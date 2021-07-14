defmodule Meadow.Pipeline.Actions.GeneratePosterImage do
  @moduledoc "Generate an image for a video FileSet from an offset"

  alias Meadow.Data.ActionStates
  alias Sequins.Pipeline.Action
  use Action
  use Meadow.Pipeline.Actions.Common

  @actiondoc "Generate poster image for a FileSet"

  defp already_complete?(_, _), do: false

  defp process(file_set, attributes, _) do
    Logger.info("Generating poster image for FileSet #{file_set.id} with offest #{attributes.offset}")

    # {result, _} =
    #   file_set
    #   |> ActionStates.set_state(__MODULE__, "ok")

    # result
  end
end
