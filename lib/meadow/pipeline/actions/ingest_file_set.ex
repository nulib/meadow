defmodule Meadow.Pipeline.Actions.IngestFileSet do
  @moduledoc "Start the ingest of a FileSet"

  alias Meadow.Data.{ActionStates, FileSet}
  alias Sequins.Pipeline.Action
  use Action
  use Meadow.Pipeline.Actions.Common

  @actiondoc "Start Ingesting a FileSet"

  defp process(%{file_set_id: file_set_id}, _, _) do
    Logger.info("Beginning ingest pipeline for FileSet #{file_set_id}")

    {result, _} =
      {FileSet, file_set_id}
      |> ActionStates.set_state(__MODULE__, "ok")

    result
  rescue
    err in RuntimeError -> {:error, err}
  end
end
