defmodule MeadowWeb.Resolvers.AIProvenance do
  @moduledoc "Resolvers for AI provenance."

  alias Meadow.AI.Provenance

  def activity(_, %{id: id}, _) do
    {:ok, Provenance.get_activity!(id)}
  end

  def activities(_, args, _) do
    criteria =
      []
      |> maybe_put(:work_id, args[:work_id])
      |> maybe_put(:file_set_id, args[:file_set_id])
      |> maybe_put(:plan_id, args[:plan_id])
      |> maybe_put(:plan_change_id, args[:plan_change_id])
      |> maybe_put(:activity_type, args[:activity_type])
      |> maybe_put(:ai_use_type, args[:ai_use_type])
      |> maybe_put(:access_mode, args[:access_mode])
      |> maybe_put(:status, args[:status])
      |> maybe_put(:limit, args[:limit])

    {:ok, Provenance.list_activities(criteria)}
  end

  def work_summary(%{id: work_id}, _, _) do
    {:ok, Provenance.work_summary(work_id)}
  end

  @doc """
  Resolve the AI provenance summary for a single file set annotation (e.g. a
  transcription), so the UI can badge it as AI-generated, AI + human edited, or
  human-authored. Returns the most recent summary entry recorded against the
  annotation, or `nil` when it carries no AI provenance.
  """
  def annotation_summary(%{id: annotation_id}, _, _) do
    summary =
      "FileSetAnnotation"
      |> Provenance.target_summary(annotation_id)
      |> List.first()

    {:ok, summary}
  end

  defp maybe_put(criteria, _key, nil), do: criteria
  defp maybe_put(criteria, key, value), do: Keyword.put(criteria, key, value)
end
