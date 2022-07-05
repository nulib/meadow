defmodule Meadow.Pipeline.Actions.IngestFileSet do
  @moduledoc "Start the ingest of a FileSet"

  alias Meadow.Data.ActionStates
  use Meadow.Pipeline.Actions.Common

  def actiondoc, do: "Start Ingesting a FileSet"

  def already_complete?(_, _), do: false

  def process(file_set, _) do
    Logger.info("Beginning ingest pipeline for FileSet #{file_set.id}")

    {result, _} =
      file_set
      |> ActionStates.set_state(__MODULE__, "ok")

    result
  rescue
    err in RuntimeError -> {:error, err}
  end
end
