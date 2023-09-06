defmodule Meadow.Pipeline.Actions.InitializeDispatch do
  @moduledoc """
  Action that sets up the rest of the actions in the pipeline
  that the file set will be dispatched to

  Subscribes to:
  * ExtractMimeType
  """
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Ingest.{Progress, Rows}
  alias Meadow.Pipeline.Dispatcher

  use Meadow.Pipeline.Actions.Common

  require Logger

  def actiondoc, do: "Initialize dispatch for rest of pipeline"

  def already_complete?(file_set, _) do
    count = length(ActionStates.get_states(file_set.id))

    case Dispatcher.initial_actions() |> length() do
      ^count ->
        false

      _ ->
        true
    end
  end

  def process(file_set, attributes) do
    Logger.info("Initializing dispatch for FileSet #{file_set.id}")

    case Dispatcher.dispatcher_actions(file_set, attributes) do
      nil ->
        err = "Invalid mime-type and file set role combination"
        ActionStates.set_state!(file_set, __MODULE__, "error", err)
        {:error, err}

      actions ->
        ActionStates.initialize_states({FileSet, file_set.id}, actions, "waiting")

        with %{context: "Sheet"} <- attributes do
          fixup_progress(FileSets.get_file_set_with_work_and_sheet!(file_set.id), attributes)
        end

        {result, _} =
          file_set
          |> ActionStates.set_state(__MODULE__, "ok")

        result
    end
  end

  defp fixup_progress(%{work: %{ingest_sheet: sheet}}, _attributes) when is_nil(sheet), do: :noop
  defp fixup_progress(%{work: work}, _attributes) when is_nil(work), do: :noop

  defp fixup_progress(%{work_id: _work_id, work: %{ingest_sheet_id: ingest_sheet_id}} = file_set, attributes) do
    Rows.get_row_by_file_set_accession_number(ingest_sheet_id, file_set.accession_number)
    |> Progress.update_entries(
      Dispatcher.not_my_actions(file_set, attributes),
      "ok"
    )
  end
end
