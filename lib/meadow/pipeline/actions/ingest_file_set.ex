defmodule Meadow.Pipeline.Actions.IngestFileSet do
  @moduledoc "Start the ingest of a FileSet"

  alias Meadow.Data.ActionStates
  alias Sequins.Pipeline.Action
  use Action
  use Meadow.Pipeline.Actions.Common

  @actiondoc "Start Ingesting a FileSet"

  defp already_complete?(_, _), do: false

  defp process(file_set, _, _) do
    Logger.info("Beginning ingest pipeline for FileSet #{file_set.id}")

    {result, _} =
      file_set
      |> ActionStates.set_state(__MODULE__, "ok")

    result
  rescue
    err in RuntimeError -> {:error, err}
  end
end
