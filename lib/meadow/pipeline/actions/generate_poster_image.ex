defmodule Meadow.Pipeline.Actions.GeneratePosterImage do
  @moduledoc "Generate an image for a video FileSet from an offset"

  alias Meadow.Config
  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Repo
  alias Meadow.Utils.Lambda
  alias Sequins.Pipeline.Action
  use Action
  use Meadow.Pipeline.Actions.Common

  @actiondoc "Generate poster image for a FileSet"

  @timeout 30_000

  defp already_complete?(_, _), do: false

  defp process(
         %FileSet{poster_offset: poster_offset, derivatives: %{"playlist" => location}} =
           file_set,
         _,
         _
       )
       when is_binary(location) and is_integer(poster_offset) do
    Logger.info(
      "Generating poster image for FileSet #{file_set.id}, with playlist: #{location} and offset: #{poster_offset}"
    )

    duration_in_milliseconds = FileSets.duration_in_milliseconds(file_set)

    if poster_offset > duration_in_milliseconds do
      {:error,
       "Offset #{poster_offset} out of range for video duration #{duration_in_milliseconds}"}
    else
      destination = FileSets.poster_uri_for(file_set)

      case generate_poster(location, destination, poster_offset) do
        {:ok, destination} ->
          Repo.transaction(fn ->
            derivatives = FileSets.add_derivative(file_set, :poster, destination)
            FileSets.update_file_set(file_set, %{derivatives: derivatives})
          end)

          :ok

        {:error, error} ->
          Logger.error("Error from lambda: #{destination}")
          {:error, error}
      end
    end
  end

  defp process(%FileSet{} = file_set, _, _) do
    Logger.error("FileSet #{file_set.id} has no value for playlist or poster_offset")

    {:error, "FileSet #{file_set.id} has no value for playlist or poster_offset"}
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
