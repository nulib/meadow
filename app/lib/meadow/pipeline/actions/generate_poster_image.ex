defmodule Meadow.Pipeline.Actions.GeneratePosterImage do
  @moduledoc "Generate an image for a video FileSet from an offset"

  alias Meadow.Config
  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Repo
  alias Meadow.Utils.{AWS, Lambda}

  use Meadow.Pipeline.Actions.Common

  @timeout 30_000

  def actiondoc, do: "Generate poster image for a FileSet"

  def already_complete?(_, _), do: false

  def process(
        %FileSet{poster_offset: poster_offset, derivatives: %{"playlist" => location}} = file_set,
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

      generate_poster(location, destination, poster_offset)
      |> handle_generate_poster_result(file_set, destination)
    end
  end

  def process(%FileSet{} = file_set, _) do
    Logger.error("FileSet #{file_set.id} has no value for playlist or poster_offset")

    {:error, "FileSet #{file_set.id} has no value for playlist or poster_offset"}
  end

  defp handle_generate_poster_result({:ok, destination}, file_set, _original_destination) do
    Repo.transaction(fn ->
      derivatives = FileSets.add_derivative(file_set, :poster, destination)
      FileSets.update_file_set(file_set, %{derivatives: derivatives})
    end)

    AWS.invalidate_cache(file_set, :poster)
  end

  defp handle_generate_poster_result({:error, error}, _file_set, destination) do
    Logger.error("Error from lambda: #{destination}")
    {:error, error}
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
