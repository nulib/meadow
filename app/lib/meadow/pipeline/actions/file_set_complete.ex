defmodule Meadow.Pipeline.Actions.FileSetComplete do
  @moduledoc "Mark the end of the FileSet ingest pipeline"

  alias Meadow.Data.ActionStates
  alias Sequins.Pipeline.Action
  use Action
  use Meadow.Pipeline.Actions.Common

  @actiondoc "Completed Processing FileSet"

  defp already_complete?(_, _), do: false

  defp process(file_set, _, _) do
    Logger.info("Ingest pipeline complete for FileSet #{file_set.id}")

    {result, _} =
      file_set
      |> ActionStates.set_state(__MODULE__, "ok")

    result
  end
end
