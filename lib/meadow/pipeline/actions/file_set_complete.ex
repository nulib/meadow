defmodule Meadow.Pipeline.Actions.FileSetComplete do
  @moduledoc "Mark the end of the FileSet ingest pipeline"

  alias Meadow.Data.{ActionStates, FileSets.FileSet}
  alias Sequins.Pipeline.Action
  use Action

  @actiondoc "Completed Processing FileSet"

  def process(data, attrs),
    do: process(data, attrs, ActionStates.ok?(data.file_set_id, __MODULE__))

  defp process(%{file_set_id: file_set_id}, _, true) do
    Logger.warn("Skipping #{__MODULE__} for #{file_set_id} – already complete")
    :ok
  end

  defp process(%{file_set_id: file_set_id}, _, _) do
    Logger.info("Ingest pipeline complete for FileSet #{file_set_id}")

    {result, _} =
      {FileSet, file_set_id}
      |> ActionStates.set_state(__MODULE__, "ok")

    result
  end
end
