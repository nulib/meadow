defmodule Meadow.AI.Provenance.Export.UVA do
  @moduledoc """
  JSON-ready projection for the UVA Archival AI Protocol Appendix B citation/log evidence.
  """

  alias Meadow.AI.Provenance

  def work(work_id) do
    activities = Provenance.list_activities(work_id: work_id)

    %{
      protocol: "UVA Archival AI Protocol",
      protocol_version: "1.1",
      scope: %{work_id: work_id},
      citation_completeness: citation_completeness(activities),
      interactions: Enum.map(activities, &activity_entry/1)
    }
  end

  defp activity_entry(activity) do
    %{
      activity_id: activity.id,
      activity_type: activity.activity_type,
      ai_use_type: activity.ai_use_type,
      access_mode: activity.access_mode,
      reversibility: activity.reversibility,
      date_time: activity.completed_at || activity.started_at || activity.inserted_at,
      system_name: activity.system_name,
      system_version: activity.system_version,
      user_category: activity.user_category,
      query_or_input_hash: input_hash(activity),
      output_retention: activity.retention_policy,
      citations: Enum.map(activity.sources || [], &citation/1),
      targets: Enum.flat_map(activity.targets || [], &target_entries/1)
    }
  end

  defp citation(source) do
    %{
      collection_id: source.collection_id,
      collection_title: source.collection_title,
      item_id: source.item_id,
      item_type: source.item_type,
      pointer: source.pointer,
      holding_organization: source.holding_organization,
      access_link: source.access_link,
      restricted: source.restricted,
      complete: complete_citation?(source)
    }
  end

  defp target_entries(target) do
    Enum.map(target.events || [], fn event ->
      %{
        target_type: target.target_type,
        target_id: target.target_id,
        field_path: target.field_path,
        operation: target.operation,
        status: target.status,
        event_type: event.event_type,
        occurred_at: event.occurred_at,
        outcome: event.outcome
      }
    end)
  end

  defp citation_completeness(activities) do
    sources = Enum.flat_map(activities, &(&1.sources || []))

    cond do
      sources == [] -> "missing_sources"
      Enum.all?(sources, &complete_citation?/1) -> "complete"
      true -> "incomplete"
    end
  end

  defp complete_citation?(source) do
    [
      source.collection_id || source.collection_title,
      source.item_id,
      source.holding_organization,
      source.access_link
    ]
    |> Enum.all?(&present?/1)
  end

  defp input_hash(%{input: nil}), do: nil
  defp input_hash(%{input: input}), do: :crypto.hash(:sha256, Jason.encode!(input)) |> Base.encode16(case: :lower)

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(nil), do: false
  defp present?(_), do: true
end
