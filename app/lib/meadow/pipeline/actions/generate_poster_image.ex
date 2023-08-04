defmodule Meadow.Pipeline.Actions.GeneratePosterImage do
  @moduledoc "Generate an image for a video FileSet from an offset"

  alias Meadow.Config
  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Repo
  alias Meadow.Utils.Lambda

  import Env

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

    iiif_cloudfront_distribution_id = Config.iiif_cloudfront_distribution_id()
    invalidate_cache(file_set, iiif_cloudfront_distribution_id)
    :ok
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

  defp invalidate_cache(file_set, nil) do
    Logger.info(
      "Skipping poster cache invalidation for file set: #{file_set.id}. No distribution id found."
    )

    :ok
  end



  defp invalidate_cache(file_set, distribution_id) do
    version = "2020-05-31"
    caller_reference = "meadow-app-#{Ecto.UUID.generate()}"

    # path = "/iiif/2/posters/#{file_set.id}/*"

    path = if System.get_env("DEV_PREFIX") do
      "/iiif/2/#{prefix()}/posters/#{file_set.id}/*"
    else
      "/iiif/2/posters/#{file_set.id}/*"
    end

    data = """
    <?xml version="1.0" encoding="UTF-8"?>
    <InvalidationBatch xmlns="http://cloudfront.amazonaws.com/doc/#{version}/">
       <CallerReference>#{caller_reference}</CallerReference>
       <Paths>
          <Items>
             <Path>#{path}</Path>
          </Items>
          <Quantity>1</Quantity>
       </Paths>
    </InvalidationBatch>
    """

    operation = %ExAws.Operation.RestQuery{
      action: :create_invalidation,
      body: data,
      http_method: :post,
      path: "/#{version}/distribution/#{distribution_id}/invalidation",
      service: :cloudfront
    }

    case operation |> ExAws.request() do
      {:ok, %{status_code: status_code}


      } when status_code in 200..299 ->
        :ok

      _ ->
        Logger.error("Unable to clear poster cache for #{path}")
        :ok
    end
  end
end
