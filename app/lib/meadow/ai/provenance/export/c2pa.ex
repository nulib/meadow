defmodule Meadow.AI.Provenance.Export.C2PA do
  @moduledoc """
  JSON-ready C2PA projection of a work's AI provenance.

  This is the *content* of a C2PA Manifest for the work's metadata record --
  actions, AI disclosures, and ingredients, named and valued per the C2PA 2.4
  specification -- not a manifest. A manifest is a signed structure bound to
  the exact bytes of an asset, so it can only be minted by whoever serializes
  the record: dc-api-v2 reads this projection from the index, adds the opening
  `c2pa.created` action and the hard binding, and signs.

  Meadow's canonical records predate (and are deliberately independent of) the
  C2PA vocabulary, so this is also where stored annotations are normalized to
  what the specification allows:

    * `c2pa.removed` means "a componentOf ingredient was removed" (18.15.1), so
      a deleted value is reported as `c2pa.deleted`.
    * A manifest has exactly one `c2pa.created` action, describing the asset as
      a whole (18.15.2), so adding a value to a field is a `c2pa.edited`.
    * `digitalSourceType` terms are the IPTC `http://` URIs (18.15.4.5).
    * `humanOversightLevel` is a closed enumeration (18.28.4).
  """

  alias Meadow.AI.Provenance

  @spec_version "2.4"

  # Entity-specific namespace for custom action parameters (C2PA 6.2.2).
  @namespace "edu.northwestern.library"

  @iptc "http://cv.iptc.org/newscodes/digitalsourcetype/"
  @composite_source_type @iptc <> "compositeWithTrainedAlgorithmicMedia"
  @human_edits_source_type @iptc <> "humanEdits"

  # The only AI model type Meadow can assert; the more specific Table 12 values
  # name serialization formats (ONNX, PyTorch, ...) of models we never hold.
  @model_type "c2pa.types.model"

  # Events that changed the live value of a field. Everything else (proposed,
  # approved, rejected, failed, transferred) is workflow, not content.
  @ai_event_types ~w(applied)
  @human_event_types ~w(human_edited human_replaced human_attested)
  @delete_event_types ~w(deleted)
  @content_event_types @ai_event_types ++ @human_event_types ++ @delete_event_types

  @unapplied_statuses ~w(proposed reviewed rejected failed)
  @live_ai_origins ~w(ai_generated ai_modified_human_content ai_assisted_human_modified)
  @relationships ~w(parentOf componentOf inputTo)

  # Least human involvement first, so the weakest claim wins when one model's
  # output received different degrees of oversight.
  @oversight_levels ~w(fully_autonomous prompt_guided human_validated)

  def work(work_id), do: work(work_id, Provenance.list_activities(work_id: work_id))

  @doc """
  Build the projection from activities that have already been loaded (with
  sources, targets, events, and agent links preloaded), so index-time callers
  can share one query across exports.
  """
  def work(work_id, activities) do
    work_id = to_string(work_id)
    entries = activities |> Enum.flat_map(&entries(&1, work_id))
    used = entries |> Enum.flat_map(& &1.action.parameters["ingredientIds"]) |> MapSet.new()

    %{
      standard: "C2PA",
      spec_version: @spec_version,
      scope: %{work_id: work_id},
      digital_source_type: digital_source_type(entries),
      actions: entries |> Enum.sort_by(&sort_key/1) |> Enum.map(&prune(&1.action)),
      ai_disclosures: ai_disclosures(entries),
      ingredients:
        activities
        |> Enum.flat_map(&(&1.sources || []))
        |> Enum.map(&ingredient/1)
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq_by(& &1.id)
        |> Enum.filter(&MapSet.member?(used, &1.id))
    }
  end

  defp entries(activity, work_id) do
    ingredient_ids =
      (activity.sources || [])
      |> Enum.map(&ingredient_id/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    (activity.targets || [])
    |> Enum.filter(&work_target?(&1, work_id))
    |> Enum.flat_map(fn target ->
      target
      |> content_events()
      |> Enum.map(fn event ->
        %{
          activity: activity,
          target: target,
          event: event,
          action: action(activity, target, event, ingredient_ids)
        }
      end)
    end)
  end

  defp work_target?(target, work_id) do
    target.target_type == "Work" and to_string(target.target_id) == work_id and
      target.status not in @unapplied_statuses
  end

  # A proposal can be edited before it is applied; those events changed the
  # proposal, not the record, so the history starts at the first event that
  # touched the live value.
  defp content_events(target) do
    (target.events || [])
    |> Enum.sort_by(&unix(&1.occurred_at))
    |> Enum.drop_while(&(&1.event_type not in (@ai_event_types ++ @delete_event_types)))
    |> Enum.filter(&(&1.event_type in @content_event_types))
  end

  defp action(activity, target, %{event_type: type} = event, ingredient_ids)
       when type in @ai_event_types do
    ai? = ai_applied?(target)

    %{
      action: if(target.operation == "delete", do: "c2pa.deleted", else: "c2pa.edited"),
      when: timestamp(event.occurred_at),
      softwareAgent: if(ai?, do: model_agent(activity), else: system_agent(activity)),
      digitalSourceType: applied_source_type(target, ai?),
      description: applied_description(target, ai?),
      parameters: parameters(activity, target, event, if(ai?, do: ingredient_ids, else: []))
    }
  end

  defp action(activity, target, %{event_type: type} = event, _ingredient_ids)
       when type in @human_event_types do
    %{
      action: "c2pa.edited",
      when: timestamp(event.occurred_at),
      softwareAgent: system_agent(activity),
      digitalSourceType: @human_edits_source_type,
      description: human_description(type, target),
      parameters: parameters(activity, target, event, [])
    }
  end

  defp action(activity, target, event, _ingredient_ids) do
    %{
      action: "c2pa.deleted",
      when: timestamp(event.occurred_at),
      softwareAgent: system_agent(activity),
      digitalSourceType: nil,
      description: "Value removed from #{target.field_path}",
      parameters: parameters(activity, target, event, [])
    }
  end

  # An applied target is AI content when it carries a digital source type; a
  # value a human added to a plan before applying it has none.
  defp ai_applied?(target), do: present?(target.digital_source_type_uri)

  defp applied_source_type(%{operation: "delete"}, _ai?), do: nil
  defp applied_source_type(target, true), do: normalize_uri(target.digital_source_type_uri)
  defp applied_source_type(_target, false), do: @human_edits_source_type

  defp applied_description(%{operation: "delete"} = target, true),
    do: "Value removed from #{target.field_path} on an AI recommendation"

  defp applied_description(%{operation: "delete"} = target, false),
    do: "Value removed from #{target.field_path}"

  defp applied_description(target, true),
    do: "AI-generated value applied to #{target.field_path}"

  defp applied_description(target, false),
    do: "Human-authored value applied to #{target.field_path}"

  defp human_description("human_attested", target),
    do: "Value of #{target.field_path} attested as human-authored"

  defp human_description("human_replaced", target),
    do: "AI-generated value of #{target.field_path} replaced by a human"

  defp human_description(_type, target),
    do: "AI-generated value of #{target.field_path} edited by a human"

  # `ingredientIds` is not a specification field: the claim generator resolves
  # each id to a hashed URI in the action's `ingredients` parameter once the
  # ingredient assertions exist.
  defp parameters(activity, target, event, ingredient_ids) do
    %{
      "ingredientIds" => ingredient_ids,
      "#{@namespace}.fieldPath" => target.field_path,
      "#{@namespace}.activityId" => activity.id,
      "#{@namespace}.eventType" => event.event_type
    }
  end

  defp model_agent(%{model: model} = activity) when is_binary(model) and model != "",
    do: %{name: model, version: activity.model_version}

  defp model_agent(activity), do: system_agent(activity)

  defp system_agent(activity),
    do: %{name: activity.system_name || "Meadow", version: activity.system_version}

  # The record as a whole is a composite once any live value is AI content.
  # Otherwise we make no claim here and leave the choice to the claim generator.
  defp digital_source_type(entries) do
    if Enum.any?(entries, &live_ai?(&1.target)), do: @composite_source_type
  end

  defp live_ai?(target), do: target.status == "applied" and target.origin in @live_ai_origins

  defp ai_disclosures(entries) do
    entries
    |> Enum.filter(&disclosable?/1)
    |> Enum.group_by(&{&1.activity.model, &1.activity.model_version})
    |> Enum.sort_by(fn {key, _entries} -> key end)
    |> Enum.map(fn {{model, version}, entries} ->
      prune(%{
        modelType: @model_type,
        modelName: model,
        modelIdentifier: model_identifier(List.first(entries).activity.model_provider, version),
        contentProfile: content_profile(entries)
      })
    end)
  end

  # An AI event that changed the live value, from an activity that names its model.
  defp disclosable?(%{event: event, target: target, activity: activity}) do
    event.event_type in @ai_event_types and ai_applied?(target) and present?(activity.model)
  end

  defp model_identifier(provider, version) do
    case Enum.filter([provider, version], &present?/1) do
      [] -> nil
      parts -> Enum.join(parts, ":")
    end
  end

  defp content_profile(entries) do
    entries
    |> Enum.map(&oversight_level(&1.target.human_oversight_level))
    |> Enum.reject(&is_nil/1)
    |> Enum.min_by(&Enum.find_index(@oversight_levels, fn level -> level == &1 end), fn -> nil end)
    |> case do
      nil -> nil
      level -> %{humanOversightLevel: level}
    end
  end

  # Meadow only runs AI at a staff member's request, so output nobody has
  # reviewed yet is prompt-guided rather than fully autonomous.
  defp oversight_level("human_review_required"), do: "prompt_guided"

  defp oversight_level(level) when level in ~w(human_reviewed human_modified human_attested),
    do: "human_validated"

  defp oversight_level(level) when level in @oversight_levels, do: level
  defp oversight_level(_), do: nil

  defp ingredient(source) do
    case ingredient_id(source) do
      nil ->
        nil

      id ->
        prune(%{
          id: id,
          "dc:title": ingredient_title(source),
          relationship: relationship(source.ingredient_relationship),
          instanceID: instance_id(source.item_id),
          informationalURI: unless(source.restricted, do: source.access_link),
          description: ingredient_description(source)
        })
    end
  end

  defp ingredient_id(%{item_id: item_id} = source) when is_binary(item_id) and item_id != "",
    do: String.downcase("#{source.item_type || "item"}:#{item_id}")

  defp ingredient_id(_), do: nil

  defp ingredient_title(source) do
    accession_number =
      case source.source_snapshot do
        %{"accession_number" => value} -> value
        %{accession_number: value} -> value
        _ -> nil
      end

    "#{source.item_type || "Item"} #{accession_number || source.item_id}"
  end

  defp ingredient_description(source) do
    [source.collection_title, source.holding_organization]
    |> Enum.filter(&present?/1)
    |> case do
      [] -> "Source material provided to the AI model"
      parts -> "Source material provided to the AI model (#{Enum.join(parts, ", ")})"
    end
  end

  defp relationship(value) when value in @relationships, do: value
  defp relationship(_), do: "inputTo"

  defp instance_id(item_id) do
    case Ecto.UUID.cast(item_id) do
      {:ok, uuid} -> "urn:uuid:#{uuid}"
      :error -> item_id
    end
  end

  defp normalize_uri("https://cv.iptc.org/" <> rest), do: "http://cv.iptc.org/" <> rest
  defp normalize_uri(uri), do: uri

  defp sort_key(entry), do: {unix(entry.event.occurred_at), entry.target.field_path}

  defp unix(nil), do: 0
  defp unix(%DateTime{} = datetime), do: DateTime.to_unix(datetime, :microsecond)

  defp timestamp(nil), do: nil
  defp timestamp(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)

  # Drop absent values (and empty lists) rather than serializing nulls into
  # what will become CBOR assertions with typed, optional fields.
  defp prune(map) when is_map(map) do
    map
    |> Enum.map(fn {key, value} -> {key, prune(value)} end)
    |> Enum.reject(fn {_key, value} -> value in [nil, [], %{}] end)
    |> Map.new()
  end

  defp prune(value), do: value

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(nil), do: false
  defp present?(_), do: true
end
