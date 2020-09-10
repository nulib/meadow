defmodule Meadow.Pipeline.Actions.FileSetComplete do
  @moduledoc "Mark the end of the FileSet ingest pipeline"

  alias Meadow.Data.{ActionStates, Schemas.FileSet}
  alias Sequins.Pipeline.Action
  use Action
  use Meadow.Pipeline.Actions.Common

  @actiondoc "Completed Processing FileSet"

  defp process(%{file_set_id: file_set_id}, _, _) do
    Logger.info("Ingest pipeline complete for FileSet #{file_set_id}")

    {result, _} =
      {FileSet, file_set_id}
      |> ActionStates.set_state(__MODULE__, "ok")

    result
  end
end
