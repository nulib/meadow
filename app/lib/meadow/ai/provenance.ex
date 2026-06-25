defmodule Meadow.AI.Provenance do
  @moduledoc """
  Canonical provenance records for AI-assisted production changes.
  """

  import Ecto.Query, warn: false
  require Logger

  alias Meadow.AI.Provenance.Schemas.{Activity, Agent, Event, EventAgent, Source, Target}
  alias Meadow.Repo

  @default_system_name "Meadow"
  @default_user_category "staff"
  @default_retention_policy "retain_internal"

  # IPTC digitalSourceType vocabulary. `trainedAlgorithmicMedia` means the value
  # was produced purely by a generative model; `algorithmicallyEnhanced` means a
  # pre-existing (human/legacy) value was modified by AI. We pick between them at
  # apply time based on whether a prior value was overwritten.
  @trained_source_type "https://cv.iptc.org/newscodes/digitalsourcetype/trainedAlgorithmicMedia"
  @enhanced_source_type "https://cv.iptc.org/newscodes/digitalsourcetype/algorithmicallyEnhanced"

  def trained_source_type, do: @trained_source_type
  def enhanced_source_type, do: @enhanced_source_type

  def create_activity(attrs) when is_map(attrs) do
    attrs
    |> normalize_activity_attrs()
    |> Activity.changeset()
    |> Repo.insert()
  end

  def complete_activity(%Activity{} = activity, attrs \\ %{}) do
    activity
    |> Activity.changeset(
      Map.merge(%{status: "completed", completed_at: DateTime.utc_now()}, attrs)
    )
    |> Repo.update()
  end

  def fail_activity(%Activity{} = activity, reason) do
    activity
    |> Activity.changeset(%{
      status: "failed",
      completed_at: DateTime.utc_now(),
      error: inspect(reason)
    })
    |> Repo.update()
  end

  def add_source(%Activity{id: activity_id}, attrs) when is_map(attrs),
    do: add_source(Map.put(attrs, :activity_id, activity_id))

  def add_source(attrs) when is_map(attrs) do
    attrs
    |> normalize_source_attrs()
    |> Source.changeset()
    |> Repo.insert()
  end

  def add_target(%Activity{id: activity_id}, attrs) when is_map(attrs),
    do: add_target(Map.put(attrs, :activity_id, activity_id))

  def add_target(attrs) when is_map(attrs) do
    attrs
    |> normalize_target_attrs()
    |> Target.changeset()
    |> Repo.insert()
  end

  def add_event(%Target{id: target_id}, attrs) when is_map(attrs),
    do: add_event(Map.put(attrs, :activity_target_id, target_id))

  def add_event(attrs) when is_map(attrs) do
    normalized_attrs = normalize_event_attrs(attrs)

    with {:ok, event} <- normalized_attrs |> Event.changeset() |> Repo.insert() do
      maybe_link_actor_agent(event, normalized_attrs)
    end
  end

  def add_agent(attrs) when is_map(attrs) do
    attrs
    |> Agent.changeset()
    |> Repo.insert()
  end

  def find_or_create_agent(attrs) when is_map(attrs) do
    normalized =
      attrs
      |> Map.put_new(:agent_type, "human")
      |> Map.update(:agent_type, "human", &to_string/1)
      |> Map.update(:name, nil, &to_string/1)

    case lookup_agent(normalized) do
      {:ok, agent} -> {:ok, agent}
      nil -> add_agent(normalized)
    end
  end

  def link_agent_to_event(%Event{id: event_id}, %Agent{id: agent_id}, role) do
    %{activity_event_id: event_id, agent_id: agent_id, role: role}
    |> EventAgent.changeset()
    |> Repo.insert(
      on_conflict: :nothing,
      conflict_target: [:activity_event_id, :agent_id, :role]
    )
  end

  def record_target(%Activity{} = activity, attrs, event_type \\ "proposed") do
    Repo.transaction(fn ->
      target = add_target!(activity, attrs)

      event_attrs =
        attrs
        |> Map.take([:actor, :notes])
        |> Map.put(:event_type, event_type)
        |> Map.put(:c2pa_action, Map.get(attrs, :c2pa_action))
        |> Map.put(:value_after, Map.get(attrs, :proposed_value))

      add_event!(target, event_attrs)
      Repo.preload(target, :events)
    end)
  end

  def record_targets_for_operations(
        %Activity{} = activity,
        target_type,
        target_id,
        operations,
        opts \\ []
      ) do
    origin = Keyword.get(opts, :origin, "ai_generated")
    status = Keyword.get(opts, :status, "proposed")
    event_type = Keyword.get(opts, :event_type, "proposed")
    actor = Keyword.get(opts, :actor)
    target_attrs = Keyword.get(opts, :target_attrs, %{})

    operations
    |> operation_targets(target_type, target_id)
    |> Enum.map(fn attrs ->
      attrs =
        attrs
        |> Map.merge(target_attrs)
        |> Map.put(:origin, origin)
        |> Map.put(:status, status)
        |> Map.put(:actor, actor)

      {:ok, target} = record_target(activity, attrs, event_type)
      target
    end)
  end

  def record_plan_manual_edit(change_before, attrs, actor) do
    activity = activity_for_plan_change(change_before)
    before_ops = plan_operation_map(change_before)
    after_ops = Map.merge(before_ops, Map.take(attrs, [:add, :delete, :replace]))

    with %Activity{} <- activity do
      before_targets = operation_targets(before_ops, "Work", change_before.work_id)
      after_targets = operation_targets(after_ops, "Work", change_before.work_id)

      removed_or_changed =
        before_targets
        |> Enum.filter(fn before_target ->
          after_target = matching_operation_target(after_targets, before_target)

          is_nil(after_target) or
            wrapped_value(after_target.proposed_value) !=
              wrapped_value(before_target.proposed_value)
        end)

      added =
        Enum.reject(after_targets, &unchanged_target?(&1, before_targets))

      Repo.transaction(fn ->
        Enum.each(
          removed_or_changed,
          &record_manual_change!(&1, activity, after_targets, actor)
        )

        Enum.each(added, &record_manual_addition!(&1, activity, actor))
      end)
    end
  end

  defp unchanged_target?(after_target, before_targets) do
    Enum.any?(before_targets, fn before_target ->
      same_target_identity?(before_target, after_target) and
        wrapped_value(before_target.proposed_value) ==
          wrapped_value(after_target.proposed_value)
    end)
  end

  defp record_manual_change!(before_target, activity, after_targets, actor) do
    existing = find_target(activity.id, before_target)
    after_target = matching_operation_target(after_targets, before_target)

    if existing do
      event_type = if is_nil(after_target), do: "human_replaced", else: "human_edited"

      origin =
        if is_nil(after_target),
          do: "human_replacement_after_ai_suggestion",
          else: "ai_assisted_human_modified"

      update_target_status_origin!(existing, origin, "reviewed")

      add_event!(existing, %{
        event_type: event_type,
        actor: actor,
        value_before: before_target.proposed_value,
        value_after: after_target && after_target.proposed_value
      })
    end
  end

  defp record_manual_addition!(after_target, activity, actor) do
    unless find_target(activity.id, after_target) do
      target =
        add_target!(
          activity,
          after_target
          |> Map.put(:origin, "human_generated")
          |> Map.put(:status, "reviewed")
        )

      add_event!(target, %{
        event_type: "human_edited",
        actor: actor,
        value_after: after_target.proposed_value
      })
    end
  end

  def record_review_for_plan_change(plan_change, event_type, actor, notes \\ nil)
      when event_type in ["approved", "rejected"] do
    plan_change
    |> activity_for_plan_change()
    |> case do
      %Activity{} = activity ->
        new_origin = if(event_type == "approved", do: "reviewed", else: "rejected")

        activity.id
        |> targets_for_activity()
        |> Enum.each(&review_target!(&1, new_origin, event_type, actor, notes))

      _ ->
        :ok
    end
  end

  # On approval the reviewing human takes editorial responsibility for the value,
  # so we advance the C2PA human_oversight_level while leaving origin (the value's
  # authorship) unchanged. Responsibility and authorship are separate axes.
  defp review_target!(target, new_status, "approved" = event_type, actor, notes) do
    target
    |> Target.changeset(%{status: new_status, human_oversight_level: "human_reviewed"})
    |> Repo.update!()

    add_event!(target, %{event_type: event_type, actor: actor, notes: notes})
  end

  defp review_target!(target, new_status, event_type, actor, notes) do
    update_target_status_origin!(target, target.origin, new_status)
    add_event!(target, %{event_type: event_type, actor: actor, notes: notes})
  end

  def record_apply_for_plan_change(plan_change, actor \\ nil, prior_values \\ %{}) do
    plan_change
    |> activity_for_plan_change()
    |> case do
      %Activity{} = activity ->
        final_targets =
          operation_targets(plan_operation_map(plan_change), "Work", plan_change.work_id)

        Enum.each(final_targets, fn final_target ->
          target =
            find_target(activity.id, final_target) ||
              add_human_apply_target!(activity, final_target)

          prior_value = Map.get(prior_values, final_target.field_path)

          record_apply_event!(target, final_target, prior_value, actor)
        end)

        maybe_complete_activity(activity)

      _ ->
        :ok
    end
  end

  @doc """
  Record the deletion of an AI-generated file set annotation (e.g. a
  transcription) as a `deleted` event on the existing provenance target, so the
  audit trail reflects that a human removed AI-generated content instead of
  leaving it asserted as `applied`. The provenance target/event persist even
  after the annotation row is gone (the target id is a plain identifier, not a
  foreign key). No-op for annotations that carry no AI provenance — i.e. no
  `ai_activity_id` or no matching applied target — so non-AI and cleanup
  deletions are not recorded.
  """
  def record_annotation_deletion(annotation, actor \\ nil)

  def record_annotation_deletion(
        %{ai_activity_id: activity_id, id: annotation_id} = annotation,
        actor
      )
      when not is_nil(activity_id) do
    case find_annotation_target(activity_id, annotation_id) do
      nil ->
        :ok

      target ->
        finalize_delete_target!(target)

        add_event!(target, %{
          event_type: "deleted",
          actor: actor,
          value_before: Map.get(annotation, :content) || wrapped_value(target.proposed_value),
          value_after: nil
        })

        :ok
    end
  end

  def record_annotation_deletion(_annotation, _actor), do: :ok

  defp find_annotation_target(activity_id, annotation_id) do
    Repo.one(
      from(t in Target,
        where: t.activity_id == ^activity_id,
        where: t.target_type == "FileSetAnnotation",
        where: t.target_id == ^to_string(annotation_id),
        order_by: [desc: t.inserted_at],
        limit: 1,
        preload: [events: [agent_links: :agent]]
      )
    )
  end

  # Origins that carry AI history, so a later human edit of the field should be
  # recorded as human mediation rather than silently keeping the AI label.
  @ai_involved_origins ~w(
    ai_generated
    ai_modified_human_content
    ai_assisted_human_modified
    human_replacement_after_ai_suggestion
  )

  @doc """
  Record a direct (non-plan) human edit of a work's fields — e.g. editing an
  AI-generated description in the Meadow edit form. For each field that already
  carries AI provenance and whose value changed, flip the origin to reflect
  human mediation and append an event capturing the AI value -> human value
  transition. Fields with no AI provenance are left untouched.
  """
  def record_work_manual_edit(work_before, work_after, actor) do
    work_before.id
    |> applied_ai_targets()
    |> Enum.each(fn target ->
      before_value = field_value(work_before, target.field_path)
      after_value = field_value(work_after, target.field_path)

      if before_value != after_value do
        record_manual_edit_for_target(target, before_value, after_value, actor)
      end
    end)

    :ok
  end

  # Persist the target reclassification and its event atomically so the
  # append-only log never gains a reclassified target with no event (or vice
  # versa). Provenance is recorded *after* the work is already saved, so a
  # failure here must not fail the user's edit: roll back this target and log
  # rather than letting the resolver crash on a successful save.
  defp record_manual_edit_for_target(target, before_value, after_value, actor) do
    Repo.transaction(fn -> apply_manual_edit!(target, before_value, after_value, actor) end)
  rescue
    error ->
      Logger.warning(
        "Failed to record manual-edit provenance for target #{target.id} " <>
          "(#{target.field_path}): #{Exception.message(error)}"
      )

      :error
  end

  # Human cleared an AI-provenanced field: this is a deletion, recorded the same
  # way as a plan-change delete (status "deleted", PREMIS "deletion",
  # `c2pa.removed`), capturing the removed AI value as `value_before`.
  defp apply_manual_edit!(target, before_value, after_value, actor)
       when after_value in [nil, "", [], %{}] do
    target
    |> Target.changeset(%{
      origin: "human_replacement_after_ai_suggestion",
      status: "deleted",
      human_oversight_level: "human_modified",
      c2pa_action: "c2pa.removed"
    })
    |> Repo.update!()

    add_event!(target, %{
      event_type: "deleted",
      actor: actor,
      value_before: before_value,
      value_after: nil
    })
  end

  # Human edited AI-generated content into a new non-empty value: an edit of AI
  # content (PREMIS "metadata modification", `c2pa.edited`).
  defp apply_manual_edit!(target, before_value, after_value, actor) do
    target
    |> Target.changeset(%{
      origin: "ai_assisted_human_modified",
      status: "applied",
      human_oversight_level: "human_modified",
      c2pa_action: "c2pa.edited"
    })
    |> Repo.update!()

    add_event!(target, %{
      event_type: "human_edited",
      actor: actor,
      value_before: before_value,
      value_after: after_value,
      c2pa_action: "c2pa.edited"
    })
  end

  @doc """
  Record a direct human edit of an AI-generated file set annotation — e.g.
  editing an AI transcription in the Access Files modal. When the annotation
  carries AI provenance (a matching applied target) and its content actually
  changed, flip the origin to reflect human mediation and append an event
  capturing the AI value -> human value transition. No-op for annotations with
  no AI provenance or unchanged content.
  """
  def record_annotation_manual_edit(annotation, new_content, actor \\ nil)

  def record_annotation_manual_edit(
        %{ai_activity_id: activity_id, id: annotation_id, content: before_content},
        new_content,
        actor
      )
      when not is_nil(activity_id) and before_content != new_content do
    case find_annotation_target(activity_id, annotation_id) do
      %Target{origin: origin} = target when origin in @ai_involved_origins ->
        record_manual_edit_for_target(target, before_content, new_content, actor)
        :ok

      _ ->
        :ok
    end
  end

  def record_annotation_manual_edit(_annotation, _new_content, _actor), do: :ok

  defp applied_ai_targets(work_id) do
    from(t in Target,
      where: t.target_type == "Work" and t.target_id == ^to_string(work_id),
      where: t.status == "applied",
      preload: [events: [agent_links: :agent]]
    )
    |> Repo.all()
    |> Enum.group_by(& &1.field_path)
    |> Enum.map(fn {_field_path, targets} -> Enum.max_by(targets, &summary_sort_key/1) end)
    |> Enum.filter(&(&1.origin in @ai_involved_origins))
  end

  # When an AI proposal overwrites a non-empty prior (human/legacy) value, the
  # applied value is an AI *modification* of human content, not a fresh
  # generation. Reflect that in origin + the IPTC digital source type so the UI,
  # PREMIS ("metadata modification"), and C2PA (`algorithmicallyEnhanced`) all
  # describe it honestly. Otherwise keep the original origin (which may already
  # be a human-edited classification). Either way, capture the overwritten value
  # on the target so the "existing data" stage is recorded uniformly, not only
  # on the applied event.
  # A plan-change `delete` removes an existing value, so record it as a deletion
  # event (PREMIS "deletion", C2PA `c2pa.removed`) on the target — capturing the
  # removed value as `value_before` — rather than a generic "applied" event.
  # Everything else applies a value as usual.
  defp record_apply_event!(target, %{operation: "delete"} = final_target, prior_value, actor) do
    finalize_delete_target!(target)

    add_event!(target, %{
      event_type: "deleted",
      actor: actor,
      value_before: prior_value || final_target.proposed_value,
      value_after: nil
    })
  end

  defp record_apply_event!(target, final_target, prior_value, actor) do
    finalize_apply_target!(target, target.origin, final_target.operation, prior_value)

    add_event!(target, %{
      event_type: "applied",
      actor: actor,
      value_before: prior_value,
      value_after: final_target.proposed_value
    })
  end

  # Mark a target as deleted by a human, reflecting the disposition of (often
  # AI-generated) content that was removed.
  defp finalize_delete_target!(target) do
    target
    |> Target.changeset(%{
      status: "deleted",
      human_oversight_level: "human_modified",
      c2pa_action: "c2pa.removed"
    })
    |> Repo.update!()
  end

  defp finalize_apply_target!(target, origin, operation, prior_value) do
    snapshot =
      if present_value?(prior_value), do: %{source_value_snapshot: wrap_value(prior_value)}, else: %{}

    attrs =
      if modification?(origin, operation, prior_value) do
        Map.merge(snapshot, %{
          origin: "ai_modified_human_content",
          status: "applied",
          digital_source_type_uri: @enhanced_source_type
        })
      else
        Map.merge(snapshot, %{origin: origin, status: "applied"})
      end

    target |> Target.changeset(attrs) |> Repo.update!()
  end

  defp modification?(origin, operation, prior_value) do
    origin in ["ai_generated"] and operation in ["replace", "delete"] and
      present_value?(prior_value)
  end

  defp present_value?(nil), do: false
  defp present_value?(value) when value in ["", [], %{}], do: false
  defp present_value?(_), do: true

  @doc """
  Snapshot the current work values for the fields a plan change will touch,
  keyed by field_path. Captured before the work is mutated so the apply step can
  tell whether the AI overwrote pre-existing content.
  """
  def prior_values_for_change(work, plan_change) do
    plan_operation_map(plan_change)
    |> operation_targets("Work", work.id)
    |> Map.new(fn %{field_path: field_path} -> {field_path, field_value(work, field_path)} end)
  end

  defp field_value(work, field_path) do
    with [section, field] <- String.split(field_path, ".", parts: 2),
         section_atom when not is_nil(section_atom) <- safe_existing_atom(section),
         field_atom when not is_nil(field_atom) <- safe_existing_atom(field),
         %{} = section_value <- Map.get(work, section_atom) do
      Map.get(section_value, field_atom)
    else
      _ -> nil
    end
  end

  defp safe_existing_atom(string) do
    String.to_existing_atom(string)
  rescue
    ArgumentError -> nil
  end

  def record_failed_plan_change(plan_change, reason) do
    plan_change
    |> activity_for_plan_change()
    |> case do
      %Activity{} = activity ->
        activity.id
        |> targets_for_activity()
        |> Enum.each(fn target ->
          update_target_status_origin!(target, target.origin, "failed")
          add_event!(target, %{event_type: "failed", notes: inspect(reason)})
        end)

        fail_activity(activity, reason)

      _ ->
        :ok
    end
  end

  def get_activity!(id), do: Repo.get!(Activity, id) |> preload_activity()

  def list_activities(criteria \\ []) do
    criteria
    |> activity_query()
    |> Repo.all()
    |> Repo.preload(activity_preloads())
  end

  def work_summary(work_id) do
    work_id
    |> targets_for_work()
    |> Enum.group_by(&summary_identity/1)
    |> Enum.map(fn {{target_type, target_id, field_path}, targets} ->
      target = Enum.max_by(targets, &summary_sort_key/1)
      activity = target.activity
      events = target.events || []
      latest_event = List.last(events)

      %{
        field_path: field_path,
        target_type: target_type,
        target_id: target_id,
        operation: target.operation,
        origin: target.origin || "human_or_legacy",
        proposed_value: target.proposed_value,
        item_provenance: merge_item_provenance(targets),
        human_oversight_level: target.human_oversight_level,
        status: target.status,
        activity_id: activity.id,
        activity_type: activity.activity_type,
        ai_use_type: activity.ai_use_type,
        access_mode: activity.access_mode,
        reversibility: activity.reversibility,
        model: activity.model,
        model_provider: activity.model_provider,
        model_version: activity.model_version,
        model_type: activity.model_type,
        generated_at:
          first_event_at(events, "proposed") || activity.completed_at || activity.inserted_at,
        reviewer: reviewer(events),
        reviewed_at: first_reviewed_at(events),
        applied_at: first_event_at(events, "applied"),
        latest_event_type: latest_event && latest_event.event_type,
        source_count: length(activity.sources || []),
        citation_completeness: citation_completeness(activity.sources || []),
        premis: premis_summary(target, latest_event),
        c2pa: c2pa_summary(activity, target, latest_event)
      }
    end)
    |> Enum.sort_by(&{&1.target_type, &1.target_id, &1.field_path})
  end

  def work_summary_map(work_id) do
    work_id
    |> work_summary()
    |> Map.new(fn summary ->
      {summary.field_path,
       %{
         origin: summary.origin,
         operation: summary.operation,
         human_oversight_level: summary.human_oversight_level,
         activity_id: summary.activity_id,
         target_type: summary.target_type,
         target_id: summary.target_id,
         status: summary.status,
         activity_type: summary.activity_type,
         ai_use_type: summary.ai_use_type,
         access_mode: summary.access_mode,
         reversibility: summary.reversibility,
         model: summary.model,
         model_provider: summary.model_provider,
         model_version: summary.model_version,
         model_type: summary.model_type,
         generated_at: summary.generated_at,
         reviewer: summary.reviewer,
         applied_at: summary.applied_at,
         source_count: summary.source_count,
         citation_completeness: summary.citation_completeness,
         premis: summary.premis,
         c2pa: summary.c2pa
       }}
    end)
  end

  def target_summary(target_type, target_id) do
    target_type
    |> targets_for_target(target_id)
    |> Enum.group_by(&summary_identity/1)
    |> Enum.map(fn {{target_type, target_id, field_path}, targets} ->
      target = Enum.max_by(targets, &summary_sort_key/1)
      activity = target.activity
      events = target.events || []
      latest_event = List.last(events)

      %{
        field_path: field_path,
        target_type: target_type,
        target_id: target_id,
        operation: target.operation,
        origin: target.origin || "human_or_legacy",
        proposed_value: target.proposed_value,
        item_provenance: merge_item_provenance(targets),
        human_oversight_level: target.human_oversight_level,
        status: target.status,
        activity_id: activity.id,
        activity_type: activity.activity_type,
        ai_use_type: activity.ai_use_type,
        access_mode: activity.access_mode,
        reversibility: activity.reversibility,
        model: activity.model,
        model_provider: activity.model_provider,
        model_version: activity.model_version,
        model_type: activity.model_type,
        generated_at:
          first_event_at(events, "proposed") || activity.completed_at || activity.inserted_at,
        reviewer: reviewer(events),
        reviewed_at: first_reviewed_at(events),
        applied_at: first_event_at(events, "applied"),
        latest_event_type: latest_event && latest_event.event_type,
        source_count: length(activity.sources || []),
        citation_completeness: citation_completeness(activity.sources || []),
        premis: premis_summary(target, latest_event),
        c2pa: c2pa_summary(activity, target, latest_event)
      }
    end)
    |> Enum.sort_by(&{&1.target_type, &1.target_id, &1.field_path})
  end

  def target_summary_map(target_type, target_id) do
    target_type
    |> target_summary(target_id)
    |> Map.new(fn summary ->
      {summary.field_path,
       %{
         origin: summary.origin,
         operation: summary.operation,
         human_oversight_level: summary.human_oversight_level,
         activity_id: summary.activity_id,
         target_type: summary.target_type,
         target_id: summary.target_id,
         status: summary.status,
         activity_type: summary.activity_type,
         ai_use_type: summary.ai_use_type,
         access_mode: summary.access_mode,
         reversibility: summary.reversibility,
         model: summary.model,
         model_provider: summary.model_provider,
         model_version: summary.model_version,
         model_type: summary.model_type,
         generated_at: summary.generated_at,
         reviewer: summary.reviewer,
         applied_at: summary.applied_at,
         latest_event_type: summary.latest_event_type,
         source_count: summary.source_count,
         citation_completeness: summary.citation_completeness,
         premis: summary.premis,
         c2pa: summary.c2pa
       }}
    end)
  end

  def operation_targets(operations, target_type, target_id) do
    operations
    |> plan_operation_map()
    |> Enum.flat_map(fn {operation, values} ->
      values
      |> flatten_operation_values()
      |> Enum.map(fn {field_path, value} ->
        %{
          target_type: target_type,
          target_id: to_string(target_id),
          field_path: field_path,
          operation: to_string(operation),
          proposed_value: value
        }
      end)
    end)
  end

  def plan_operation_map(plan_change_or_map) do
    %{
      add: map_value(plan_change_or_map, :add) || %{},
      delete: map_value(plan_change_or_map, :delete) || %{},
      replace: map_value(plan_change_or_map, :replace) || %{}
    }
    |> Enum.reject(fn {_op, value} -> is_nil(value) or value == %{} end)
    |> Map.new()
  end

  defp normalize_activity_attrs(attrs) do
    attrs
    |> Map.put_new(:system_name, @default_system_name)
    |> Map.put_new(:user_category, @default_user_category)
    |> Map.put_new(:retention_policy, @default_retention_policy)
    |> Map.put_new(:access_mode, "retrieval_based")
    |> Map.put_new(:reversibility, "reversible")
    |> Map.put_new(:model_type, "generative_ai")
    |> Map.put_new(:started_at, DateTime.utc_now())
  end

  defp normalize_source_attrs(attrs) do
    attrs
    |> Map.put_new(:relationship_role, "source")
    |> Map.put_new(:premis_object_category, source_object_category(attrs))
    |> put_object_identifier()
  end

  defp normalize_target_attrs(attrs) do
    attrs
    |> Map.put_new(:premis_object_category, target_object_category(attrs))
    |> Map.put_new(:c2pa_action, c2pa_action_for_operation(map_value(attrs, :operation)))
    |> Map.put_new(:human_oversight_level, human_oversight_for_origin(map_value(attrs, :origin)))
    |> put_object_identifier()
    |> Map.update(:proposed_value, nil, &wrap_value/1)
    |> Map.update(:source_value_snapshot, nil, &wrap_value/1)
  end

  defp normalize_event_attrs(attrs) do
    attrs
    |> Map.put_new(:premis_event_type, premis_event_type(map_value(attrs, :event_type)))
    |> Map.put_new(:outcome, event_outcome(map_value(attrs, :event_type)))
    |> Map.put_new(:c2pa_action, c2pa_action_for_event(map_value(attrs, :event_type)))
    |> Map.update(:value_before, nil, &wrap_value/1)
    |> Map.update(:value_after, nil, &wrap_value/1)
  end

  defp wrap_value(nil), do: nil
  defp wrap_value(%{"value" => _} = value), do: value
  defp wrap_value(%{value: _} = value), do: atom_keys_to_strings(value)
  defp wrap_value(value), do: %{"value" => json_safe(value)}
  defp wrapped_value(nil), do: nil
  defp wrapped_value(%{proposed_value: value}), do: wrapped_value(value)
  defp wrapped_value(%{"value" => value}), do: value
  defp wrapped_value(%{value: value}), do: value
  defp wrapped_value(value), do: value

  defp json_safe(value), do: value |> Jason.encode!() |> Jason.decode!()

  @doc """
  Per-item AI attribution for a multivalued field (subjects, descriptions, …),
  reconciling the AI's original proposal against the field's current value so
  each item carries an honest origin:

    * an item the AI proposed that is still present unchanged -> `ai_generated`
    * an item the AI proposed that a human has since edited in place -> the
      field's edit origin (`ai_assisted_human_modified` / `ai_modified_human_content`)
    * an item a human added outright -> omitted (it carries no AI lineage)

  Entries are keyed by the item's *current* identifier (a term id for controlled
  terms, the raw string for free text) so the UI can line each displayed value up
  with its attribution. Because works store multivalued fields as positional
  lists with no stable per-item ids, unchanged items are matched by value and the
  remainder positionally; reordering a list can therefore blur which item an edit
  applies to, but in-place edits (the common case) are attributed correctly.
  Shared by the work About tab (`item_provenance` on the provenance summary) and
  the plan diff, so both stages show identical per-item attribution.
  """
  def item_provenance(%Target{} = target),
    do: ai_item_provenance(target, target.events || [])

  # A single field's value can be touched by several targets (e.g. one activity
  # replaces a note and a later one adds another), so per-item attribution is the
  # union of every target's items. Targets are merged oldest-first and deduped by
  # id, so when two targets touch the same item the most recent attribution wins.
  defp merge_item_provenance(targets) do
    targets
    |> Enum.sort_by(&summary_sort_key/1)
    |> Enum.flat_map(&ai_item_provenance(&1, &1.events || []))
    |> Enum.reverse()
    |> Enum.uniq_by(& &1.id)
    |> Enum.reverse()
  end

  defp ai_item_provenance(target, events) do
    reconcile_items(
      proposed_value(target, events),
      current_value(target, events),
      item_edit_origin(target)
    )
  end

  # The AI's untouched suggestion: the `proposed` event's value, falling back to
  # the target's proposed_value.
  defp proposed_value(target, events) do
    case Enum.find(events, &(&1.event_type == "proposed")) do
      %{value_after: value} when not is_nil(value) -> value
      _ -> target.proposed_value
    end
  end

  # The field's current value: the most recent value a human edit or apply step
  # recorded; before any such event it is the AI's untouched proposal. Review
  # events (approved/rejected) carry no value, so they are ignored here.
  # `occurred_at` must be compared with `DateTime` — default term ordering sorts
  # `DateTime` structs by microsecond before second and would pick the wrong one.
  defp current_value(target, events) do
    events
    |> Enum.reject(&(&1.event_type == "proposed" or is_nil(&1.value_after)))
    |> case do
      [] -> target.proposed_value
      later -> Enum.max_by(later, & &1.occurred_at, DateTime).value_after
    end
  end

  # Reconcile the proposed and current item lists into per-item attribution.
  # Items present in both (by id) are unchanged AI generations; the leftover
  # current items are matched positionally to dropped proposed items and treated
  # as in-place human edits of those AI items, while any current items beyond the
  # dropped proposed items are human additions and carry no AI lineage.
  defp reconcile_items(proposed_val, current_val, edit_origin) do
    proposed = value_item_ids(proposed_val)
    current = value_item_ids(current_val)

    proposed_set = MapSet.new(proposed)
    current_set = MapSet.new(current)

    {unchanged, edited_current} =
      Enum.split_with(current, &MapSet.member?(proposed_set, &1))

    dropped_proposed = Enum.reject(proposed, &MapSet.member?(current_set, &1))

    edited =
      edited_current
      |> Enum.zip(dropped_proposed)
      |> Enum.map(fn {id, _was} -> %{id: id, origin: edit_origin} end)

    Enum.map(unchanged, &%{id: &1, origin: "ai_generated"}) ++ edited
  end

  defp item_edit_origin(%{origin: "ai_modified_human_content"}), do: "ai_modified_human_content"
  defp item_edit_origin(_), do: "ai_assisted_human_modified"

  defp value_item_ids(%{"value" => list}) when is_list(list) do
    list |> Enum.map(&item_identifier/1) |> Enum.reject(&is_nil/1)
  end

  defp value_item_ids(list) when is_list(list) do
    list |> Enum.map(&item_identifier/1) |> Enum.reject(&is_nil/1)
  end

  defp value_item_ids(_), do: []

  defp item_identifier(%{"term" => %{"id" => id}}), do: id
  defp item_identifier(%{term: %{id: id}}), do: id
  defp item_identifier(%{"note" => note}) when is_binary(note), do: note
  defp item_identifier(%{note: note}) when is_binary(note), do: note
  defp item_identifier(%{"url" => url}) when is_binary(url), do: url
  defp item_identifier(%{url: url}) when is_binary(url), do: url
  defp item_identifier(%{"edtf" => edtf}) when is_binary(edtf), do: edtf
  defp item_identifier(%{edtf: edtf}) when is_binary(edtf), do: edtf
  defp item_identifier(%{"id" => id}), do: id
  defp item_identifier(value) when is_binary(value), do: value
  defp item_identifier(_), do: nil

  defp atom_keys_to_strings(value), do: value |> Jason.encode!() |> Jason.decode!()

  defp add_target!(activity, attrs), do: add_target!(Map.put(attrs, :activity_id, activity.id))

  defp add_target!(attrs),
    do: attrs |> normalize_target_attrs() |> Target.changeset() |> Repo.insert!()

  defp add_human_apply_target!(activity, attrs) do
    add_target!(
      activity,
      attrs
      |> Map.put(:origin, "human_generated")
      |> Map.put(:status, "applied")
    )
  end

  defp add_event!(target, attrs), do: add_event!(Map.put(attrs, :activity_target_id, target.id))

  defp add_event!(attrs) do
    {:ok, event} = add_event(attrs)
    event
  end

  defp maybe_complete_activity(%Activity{status: "completed"} = activity), do: {:ok, activity}
  defp maybe_complete_activity(%Activity{} = activity), do: complete_activity(activity)

  defp update_target_status_origin!(target, origin, status) do
    target
    |> Target.changeset(%{origin: origin, status: status})
    |> Repo.update!()
  end

  defp activity_for_plan_change(%{ai_activity_id: nil}), do: nil
  defp activity_for_plan_change(%{ai_activity_id: id}), do: Repo.get(Activity, id)

  defp targets_for_activity(activity_id) do
    Repo.all(
      from(t in Target,
        where: t.activity_id == ^activity_id,
        preload: [events: [agent_links: :agent]]
      )
    )
  end

  defp find_target(activity_id, target_attrs) do
    Repo.one(
      from(t in Target,
        where: t.activity_id == ^activity_id,
        where: t.target_type == ^target_attrs.target_type,
        where: t.target_id == ^to_string(target_attrs.target_id),
        where: t.field_path == ^target_attrs.field_path,
        where: t.operation == ^target_attrs.operation,
        order_by: [desc: t.inserted_at],
        limit: 1,
        preload: [events: [agent_links: :agent]]
      )
    )
  end

  defp matching_operation_target(targets, target) do
    Enum.find(targets, &same_target_identity?(&1, target))
  end

  defp same_target_identity?(left, right) do
    left.target_type == right.target_type and
      to_string(left.target_id) == to_string(right.target_id) and
      left.field_path == right.field_path and
      left.operation == right.operation
  end

  defp flatten_operation_values(%{} = values) do
    Enum.flat_map(values, fn {section, section_values} ->
      flatten_section_values(to_string(section), section_values)
    end)
  end

  defp flatten_operation_values(_), do: []

  defp flatten_section_values(section, %{} = section_values) do
    Enum.map(section_values, fn {field, value} -> {"#{section}.#{field}", value} end)
  end

  defp flatten_section_values(section, value), do: [{section, value}]

  defp map_value(%{} = map, key), do: Map.get(map, key) || Map.get(map, to_string(key))
  defp map_value(struct, key), do: Map.get(struct, key)

  defp activity_query(criteria) do
    query = from(a in Activity, order_by: [desc: a.inserted_at])

    Enum.reduce(criteria, query, fn
      {:id, id}, query -> from(a in query, where: a.id == ^id)
      {:work_id, nil}, query -> from(a in query, where: is_nil(a.work_id))
      {:work_id, id}, query -> from(a in query, where: a.work_id == ^id)
      {:file_set_id, nil}, query -> from(a in query, where: is_nil(a.file_set_id))
      {:file_set_id, id}, query -> from(a in query, where: a.file_set_id == ^id)
      {:plan_id, id}, query -> from(a in query, where: a.plan_id == ^id)
      {:plan_change_id, id}, query -> from(a in query, where: a.plan_change_id == ^id)
      {:activity_type, type}, query -> from(a in query, where: a.activity_type == ^type)
      {:ai_use_type, type}, query -> from(a in query, where: a.ai_use_type == ^type)
      {:access_mode, mode}, query -> from(a in query, where: a.access_mode == ^mode)
      {:status, status}, query -> from(a in query, where: a.status == ^status)
      {:limit, limit}, query -> from(a in query, limit: ^limit)
    end)
  end

  defp targets_for_work(work_id) do
    Repo.all(
      from(t in Target,
        join: a in assoc(t, :activity),
        left_join: s in assoc(a, :sources),
        where:
          (t.target_type == "Work" and t.target_id == ^to_string(work_id)) or
            a.work_id == ^work_id or
            s.work_id == ^work_id,
        preload: [
          activity: {a, [:sources]},
          events:
            ^from(e in Event,
              order_by: [asc: e.occurred_at],
              preload: [agent_links: :agent]
            )
        ],
        distinct: t.id
      )
    )
  end

  defp targets_for_target(target_type, target_id) do
    Repo.all(
      from(t in Target,
        join: a in assoc(t, :activity),
        where: t.target_type == ^to_string(target_type),
        where: t.target_id == ^to_string(target_id),
        preload: [
          activity: {a, [:sources]},
          events:
            ^from(e in Event,
              order_by: [asc: e.occurred_at],
              preload: [agent_links: :agent]
            )
        ],
        distinct: t.id
      )
    )
  end

  defp activity_preloads, do: [:sources, targets: [events: [agent_links: :agent]]]

  defp preload_activity(nil), do: nil
  defp preload_activity(%Activity{} = activity), do: Repo.preload(activity, activity_preloads())

  defp lookup_agent(%{identifier_type: type, identifier_value: value})
       when is_binary(type) and is_binary(value) do
    case Repo.get_by(Agent, identifier_type: type, identifier_value: value) do
      nil -> nil
      agent -> {:ok, agent}
    end
  end

  defp lookup_agent(%{agent_type: type, name: name, version: version})
       when is_binary(type) and is_binary(name) do
    case Repo.get_by(Agent, agent_type: type, name: name, version: version) do
      nil -> nil
      agent -> {:ok, agent}
    end
  end

  defp lookup_agent(_), do: nil

  defp maybe_link_actor_agent(%Event{} = event, attrs) do
    actor = map_value(attrs, :actor)

    if is_binary(actor) and actor != "" do
      with {:ok, agent} <-
             find_or_create_agent(%{
               agent_type: "human",
               name: actor,
               identifier_type: "local",
               identifier_value: actor
             }),
           {:ok, _link} <- link_agent_to_event(event, agent, event_agent_role(attrs)) do
        {:ok, Repo.preload(event, agent_links: :agent)}
      else
        {:error, _} = error -> error
      end
    else
      {:ok, event}
    end
  end

  defp event_agent_role(attrs) do
    map_value(attrs, :agent_role) ||
      case map_value(attrs, :event_type) do
        event when event in ["approved", "rejected", "human_edited", "human_replaced"] ->
          "reviewer"

        "applied" ->
          "operator"

        _ ->
          "actor"
      end
  end

  defp put_object_identifier(attrs) do
    attrs
    |> Map.put_new(:object_identifier_type, "Meadow")
    |> Map.put_new(:object_identifier_value, map_value(attrs, :target_id) || map_value(attrs, :item_id))
  end

  defp source_object_category(attrs) do
    case map_value(attrs, :item_type) do
      "FileSet" -> "file"
      "FileSetAnnotation" -> "representation"
      "Collection" -> "intellectual_entity"
      _ -> "intellectual_entity"
    end
  end

  defp target_object_category(attrs) do
    case map_value(attrs, :target_type) do
      "FileSet" -> "file"
      "FileSetAnnotation" -> "representation"
      "Work" -> "intellectual_entity"
      _ -> "representation"
    end
  end

  defp c2pa_action_for_operation("add"), do: "c2pa.created"
  defp c2pa_action_for_operation("replace"), do: "c2pa.edited"
  defp c2pa_action_for_operation("delete"), do: "c2pa.removed"
  defp c2pa_action_for_operation(_), do: nil

  defp c2pa_action_for_event("applied"), do: "c2pa.edited"
  defp c2pa_action_for_event("deleted"), do: "c2pa.removed"
  defp c2pa_action_for_event("legacy_note_migrated"), do: "c2pa.opened"
  defp c2pa_action_for_event(_), do: nil

  defp human_oversight_for_origin(origin)
       when origin in ["ai_assisted_human_modified", "human_replacement_after_ai_suggestion"],
       do: "human_modified"

  defp human_oversight_for_origin("ai_generated"), do: "human_review_required"
  defp human_oversight_for_origin("human_generated"), do: "human_created"
  defp human_oversight_for_origin(_), do: nil

  defp premis_event_type("proposed"), do: "metadata generation"
  defp premis_event_type("human_edited"), do: "metadata modification"
  defp premis_event_type("human_replaced"), do: "metadata replacement"
  defp premis_event_type("approved"), do: "validation"
  defp premis_event_type("rejected"), do: "validation"
  defp premis_event_type("applied"), do: "metadata update"
  defp premis_event_type("deleted"), do: "deletion"
  defp premis_event_type("failed"), do: "metadata update"
  defp premis_event_type("legacy_note_migrated"), do: "metadata migration"
  defp premis_event_type(value), do: value

  defp event_outcome("rejected"), do: "failure"
  defp event_outcome("failed"), do: "failure"
  defp event_outcome(_), do: "success"

  defp summary_identity(target), do: {target.target_type, target.target_id, target.field_path}

  defp citation_completeness([]), do: "missing_sources"

  defp citation_completeness(sources) do
    if Enum.all?(sources, &complete_citation?/1), do: "complete", else: "incomplete"
  end

  defp complete_citation?(source) do
    Enum.all?(
      [
        source.collection_id || source.collection_title,
        source.item_id,
        source.holding_organization,
        source.access_link
      ],
      &present?/1
    )
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(nil), do: false
  defp present?(_), do: true

  defp premis_summary(target, event) do
    %{
      object_category: target.premis_object_category,
      event_type: event && event.premis_event_type,
      event_outcome: event && event.outcome,
      linking_object_role: target.operation,
      object_identifier_type: target.object_identifier_type,
      object_identifier_value: target.object_identifier_value
    }
  end

  defp c2pa_summary(activity, target, event) do
    action = target.c2pa_action || event_field(event, :c2pa_action)

    %{
      action: action,
      digital_source_type_uri: target.digital_source_type_uri,
      ingredient_relationship: target.ingredient_relationship,
      human_oversight_level: target.human_oversight_level,
      manifest_id: target.c2pa_manifest_id || activity.c2pa_manifest_id,
      claim_id: target.c2pa_claim_id || activity.c2pa_claim_id,
      assertion_label: target.c2pa_assertion_label || event_field(event, :c2pa_assertion_label),
      validation_status: target.c2pa_validation_status || activity.c2pa_validation_status,
      signature_status: target.c2pa_signature_status || activity.c2pa_signature_status,
      ready:
        present?(action) and present?(target.digital_source_type_uri) and
          present?(target.human_oversight_level)
    }
  end

  defp event_field(nil, _key), do: nil
  defp event_field(event, key), do: Map.get(event, key)

  # Sort key for choosing the target that represents a field's *current*
  # provenance state when several activities have touched the same field. We
  # want the most recent action to win, so a later AI re-generation supersedes
  # an earlier human replacement (rather than the "Human replaced AI" label
  # sticking around). The key is a fully-ordered tuple — latest event time,
  # then the target's own creation time, then its id — so `Enum.max_by` is
  # deterministic even when two targets share an event timestamp (down to the
  # microsecond) instead of falling back to arbitrary row order. We compare on
  # unix microseconds so the ordering is chronological rather than relying on
  # DateTime struct term order.
  defp summary_sort_key(target) do
    latest_event =
      target.events
      |> Enum.map(& &1.occurred_at)
      |> Enum.reject(&is_nil/1)
      |> Enum.max(DateTime, fn -> target.inserted_at end)

    {DateTime.to_unix(latest_event, :microsecond),
     DateTime.to_unix(target.inserted_at, :microsecond), target.id}
  end

  defp first_event_at(events, type) do
    events
    |> Enum.find(&(&1.event_type == type))
    |> case do
      nil -> nil
      event -> event.occurred_at
    end
  end

  defp reviewer(events) do
    events
    |> Enum.find(&(&1.event_type in ["approved", "rejected", "human_edited", "human_replaced"]))
    |> case do
      nil -> nil
      event -> event.actor
    end
  end

  defp first_reviewed_at(events) do
    events
    |> Enum.find(&(&1.event_type in ["approved", "rejected", "human_edited", "human_replaced"]))
    |> case do
      nil -> nil
      event -> event.occurred_at
    end
  end
end
