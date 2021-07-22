defmodule Meadow.Pipeline.Actions.GeneratePosterImage do
  @moduledoc "Generate an image for a video FileSet from an offset"

  alias Meadow.Config
  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Utils.Lambda
  alias Sequins.Pipeline.Action
  use Action
  use Meadow.Pipeline.Actions.Common

  @actiondoc "Generate poster image for a FileSet"

  @timeout 30_000

  defp already_complete?(_, _), do: false

  defp process(
         %FileSet{derivatives: %{"playlist" => location}} = file_set,
         attributes,
         _
       )
       when is_binary(location) do
    Logger.info(
      "Generating poster image for FileSet #{file_set.id}, with playlist: #{location} and offset: #{attributes[:offset]}"
    )

    destination = FileSets.poster_uri_for(file_set)

    case generate_poster(location, destination, attributes[:offset]) do
      {:ok, _dest} ->
        :ok

      {:error, error} ->
        {:error, error}
    end
  end

  defp process(%FileSet{} = file_set, _attributes, _) do
    Logger.error("FileSet #{file_set.id} has no value for playlist")

    {:error, "FileSet #{file_set.id} has no value for playlist"}
  end

  defp generate_poster(location, destination, offset) do
    Lambda.invoke(
      Config.lambda_config(:frame_extractor),
      %{
        source: location,
        destination: destination,
        offset: offset
      },
      @timeout
    )
  end
end
