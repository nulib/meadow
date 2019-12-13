defmodule Meadow.Ingest.Progress do
  @moduledoc """
  Translate action state notifications into ingest sheet progress notifications
  """

  alias Meadow.Ingest.Sheets

  def send_notification(action_state) do
    case Sheets.ingest_sheet_for_file_set(action_state.object_id) do
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
    case Sheets.total_action_count(ingest_sheet) do
      0 ->
        %{
          sheet_id: ingest_sheet.id,
          total_file_sets: 0,
          completed_file_sets: 0,
          total_actions: 0,
          completed_actions: 0,
          percent_complete: 0
        }

      action_count ->
        completed_action_count = Sheets.completed_action_count(ingest_sheet)
        percent_complete = round(completed_action_count / action_count * 10_000) / 100

        %{
          sheet_id: ingest_sheet.id,
          total_file_sets: Sheets.file_set_count(ingest_sheet),
          completed_file_sets: Sheets.completed_file_set_count(ingest_sheet),
          total_actions: action_count,
          completed_actions: completed_action_count,
          percent_complete: percent_complete
        }
    end
  end
end
