defmodule Meadow.Pipeline.Actions.FileSetComplete do
  @moduledoc "Mark the end of the FileSet ingest pipeline"

  alias Meadow.Data.ActionStates
  use Meadow.Pipeline.Actions.Common

  def actiondoc, do: "Completed Processing FileSet"

  def already_complete?(_, _), do: false

  def process(file_set, _) do
    Logger.info("Ingest pipeline complete for FileSet #{file_set.id}")

    {result, _} =
      file_set
      |> ActionStates.set_state(__MODULE__, "ok")

    result
  end
end
