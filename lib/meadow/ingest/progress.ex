defmodule Meadow.Ingest.Progress do
  @moduledoc """
  Translate action state notifications into ingest sheet progress notifications
  """
  alias Meadow.Data.Works
  alias Meadow.Ingest
  alias Meadow.Ingest.Sheets

  defstruct sheet_id: nil,
            total_file_sets: 0,
            completed_file_sets: 0,
            total_actions: 0,
            completed_actions: 0,
            percent_complete: 0

  def send_notification(%{object_id: file_set_id, object_type: "Meadow.Data.Schemas.FileSet"}) do
    case Ingest.ingest_sheet_for_file_set(file_set_id) do
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

  def send_notification(%{object_id: work_id, object_type: "Meadow.Data.Schemas.Work"}) do
    with work <- Works.with_sheet(work_id) do
      Absinthe.Subscription.publish(
        MeadowWeb.Endpoint,
        pipeline_progress(work.ingest_sheet),
        ingest_progress: work.ingest_sheet_id
      )
    end
  end

  def send_notification(_), do: :noop

  def pipeline_progress(ingest_sheet) do
    case Sheets.total_action_count(ingest_sheet) do
      0 ->
        %__MODULE__{sheet_id: ingest_sheet.id}

      action_count ->
        completed_action_count = Sheets.completed_action_count(ingest_sheet)
        percent_complete = round(completed_action_count / action_count * 10_000) / 100

        %__MODULE__{
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
