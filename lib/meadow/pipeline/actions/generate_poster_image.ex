defmodule Meadow.Pipeline.Actions.GeneratePosterImage do
  @moduledoc "Generate an image for a video FileSet from an offset"

  alias Meadow.Config
  alias Meadow.Data.ActionStates
  alias Meadow.Utils.Lambda
  alias Sequins.Pipeline.Action
  use Action
  use Meadow.Pipeline.Actions.Common

  @actiondoc "Generate poster image for a FileSet"

  @timeout 120_000

  defp already_complete?(_, _), do: false

  defp process(file_set, attributes, _) do
    Logger.info(
      "Generating poster image for FileSet #{file_set.id} with offest #{attributes.offset}"
    )

    Lambda.invoke(
      Config.lambda_config(:frame_extractor),
      %{
        source_bucket: Config.streaming_bucket(),
        dest_bucket: Config.streaming_bucket(),
        key: "6298d09f04833eb737504941812b0442e6253a4e286e79db3b11e16f9b39c604-1080_00001.ts",
        offset: "5"
      },
      @timeout
    )
  end
end
