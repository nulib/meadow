defmodule Meadow.Ingest.IngestSheets.IngestSheetProgress do
  @moduledoc """
  Translate audit entry notifications into ingest sheet progress notifications
  """

  alias Meadow.Ingest.IngestSheets

  def send_notification(audit_entry) do
    case IngestSheets.ingest_sheet_for_file_set(audit_entry.object_id) do
      nil ->
        :noop

      sheet ->
        Absinthe.Subscription.publish(
          MeadowWeb.Endpoint,
          pipeline_progress(sheet),
          ingest_progress: sheet.id
        )
    end
  end

  defp pipeline_progress(ingest_sheet) do
    case IngestSheets.total_action_count(ingest_sheet) do
      0 ->
        %{
          ingest_sheet_id: ingest_sheet.id,
          total_file_sets: 0,
          completed_file_sets: 0,
          total_actions: 0,
          completed_actions: 0,
          percent_complete: 0
        }

      action_count ->
        completed_action_count = IngestSheets.completed_action_count(ingest_sheet)
        percent_complete = round(completed_action_count / action_count * 10_000) / 100

        %{
          ingest_sheet_id: ingest_sheet.id,
          total_file_sets: IngestSheets.file_set_count(ingest_sheet),
          completed_file_sets: IngestSheets.completed_file_set_count(ingest_sheet),
          total_actions: action_count,
          completed_actions: completed_action_count,
          percent_complete: percent_complete
        }
    end
  end
end
