defmodule Meadow.AI.Provenance.Export.PREMIS do
  @moduledoc """
  JSON-ready PREMIS-oriented projection for AI provenance records.

  This is intentionally entity-shaped rather than XML-specific so dc-api-v2 can expose a
  public JSON representation first and add XML/RDF serialization later.
  """

  alias Meadow.AI.Provenance

  def work(work_id) do
    activities = Provenance.list_activities(work_id: work_id)

    %{
      premis_version: "3.0",
      scope: %{work_id: work_id},
      objects: activities |> Enum.flat_map(&objects/1) |> uniq_by_id(),
      events: activities |> Enum.flat_map(&events/1),
      agents: activities |> Enum.flat_map(&agents/1) |> uniq_by_id(),
      rights: activities |> Enum.map(&rights_statement/1) |> Enum.reject(&is_nil/1)
    }
  end

  defp objects(activity) do
    source_objects =
      Enum.map(activity.sources || [], fn source ->
        %{
          identifier: object_identifier(source.object_identifier_type, source.object_identifier_value || source.item_id),
          category: source.premis_object_category,
          role: source.relationship_role || "source",
          type: source.item_type,
          work_id: source.work_id,
          file_set_id: source.file_set_id,
          access_link: source.access_link,
          restricted: source.restricted,
          fixity: fixity(source)
        }
      end)

    target_objects =
      Enum.map(activity.targets || [], fn target ->
        %{
          identifier: object_identifier(target.object_identifier_type, target.object_identifier_value || target.target_id),
          category: target.premis_object_category,
          role: target.operation || "target",
          type: target.target_type,
          target_id: target.target_id,
          field_path: target.field_path,
          restricted: target.restricted,
          fixity: fixity(target)
        }
      end)

    source_objects ++ target_objects
  end

  defp events(activity) do
    Enum.flat_map(activity.targets || [], fn target ->
      Enum.map(target.events || [], fn event ->
        %{
          identifier: %{type: "Meadow AI activity event", value: event.id},
          type: event.premis_event_type || event.event_type,
          date_time: event.occurred_at,
          outcome: event.outcome,
          outcome_detail: event.outcome_detail || event.notes,
          activity_id: activity.id,
          target: object_identifier(target.object_identifier_type, target.object_identifier_value || target.target_id),
          linking_agents: linking_agents(event)
        }
      end)
    end)
  end

  defp agents(activity) do
    activity_agents =
      [
        agent("software", activity.system_name, "system", activity.system_version),
        agent("model", activity.model, "model", activity.model_version)
      ]
      |> Enum.reject(&is_nil/1)

    event_agents =
      (activity.targets || [])
      |> Enum.flat_map(&(&1.events || []))
      |> Enum.flat_map(fn event ->
        (event.agent_links || [])
        |> Enum.map(& &1.agent)
        |> Enum.reject(&is_nil/1)
        |> Enum.map(fn agent ->
          %{
            identifier: object_identifier(agent.identifier_type || agent.agent_type, agent.identifier_value || agent.id),
            type: agent.agent_type,
            name: agent.name,
            version: agent.version
          }
        end)
      end)

    activity_agents ++ event_agents
  end

  defp linking_agents(event) do
    Enum.map(event.agent_links || [], fn link ->
      %{
        role: link.role,
        agent_identifier:
          object_identifier(
            link.agent && (link.agent.identifier_type || link.agent.agent_type),
            link.agent && (link.agent.identifier_value || link.agent.id)
          )
      }
    end)
  end

  defp rights_statement(%{retention_policy: nil}), do: nil

  defp rights_statement(activity) do
    %{
      basis: "policy",
      policy: activity.retention_policy,
      activity_id: activity.id,
      note: "AI provenance retention policy recorded by Meadow"
    }
  end

  defp agent(_type, nil, _identifier_type, _version), do: nil

  defp agent(type, name, identifier_type, version) do
    %{
      identifier: object_identifier(identifier_type, name),
      type: type,
      name: name,
      version: version
    }
  end

  defp object_identifier(nil, nil), do: nil
  defp object_identifier(type, value), do: %{type: type, value: value}

  defp fixity(%{content_hash: nil}), do: nil
  defp fixity(%{content_hash: hash, content_hash_algorithm: algorithm}) do
    %{message_digest_algorithm: algorithm, message_digest: hash}
  end

  defp uniq_by_id(items) do
    items
    |> Enum.reject(&is_nil(&1.identifier))
    |> Enum.uniq_by(& &1.identifier)
  end
end
