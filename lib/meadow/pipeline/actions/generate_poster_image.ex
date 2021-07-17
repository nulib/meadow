defmodule Meadow.Pipeline.Actions.GeneratePosterImage do
  @moduledoc "Generate an image for a video FileSet from an offset"

  alias Meadow.Config
  # alias Meadow.Data.ActionStates
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
    key = Map.get(attributes, :key)
    offset = Map.get(attributes, :offset)

    case generate_poster(key, offset) do
      {:ok, _dest} ->
        :ok

      {:error, error} -> {:error, error}
    end
  end

  defp generate_poster(key, offset) do
    Lambda.invoke(
      Config.lambda_config(:frame_extractor),
      %{
        source: Config.streaming_bucket(),
        dest: Config.streaming_bucket(),
        key: key,
        offset: offset
      },
      @timeout
    )
  end
end
