defmodule MeadowWeb.MCP.Tools.PreviewThumbnail do
  @moduledoc """
  Builds the small base64 JPEG thumbnails embedded in AI metadata previews.

  Both the ingest-sheet (`SubmitAIPreviews`) and ArchivesSpace
  (`SubmitArchivesSpacePreviews`) preview tools attach a thumbnail to each
  preview so the review UI can show what the agent looked at. The image
  lives in the ingest bucket at the preview's `filename` S3 URI; this module
  fetches it, downscales it, and re-encodes it as a JPEG.
  """

  require Logger

  @max_dimension 512

  @doc """
  Adds a `:thumbnail` (base64 JPEG string) to a preview map based on its
  `:filename` S3 URI. Returns the preview unchanged when the image can't be
  fetched or decoded, so a missing thumbnail never blocks a preview.
  """
  def add(%{filename: filename} = preview) do
    %URI{host: bucket, path: "/" <> key} = URI.parse(filename)

    case fetch(bucket, key) do
      {:ok, base64} ->
        Map.put(preview, :thumbnail, base64)

      {:error, reason} ->
        Logger.warning("PreviewThumbnail: could not fetch thumbnail for #{filename}: #{inspect(reason)}")
        preview
    end
  end

  defp fetch(bucket, key) do
    case ExAws.S3.get_object(bucket, key) |> ExAws.request() do
      {:ok, %{body: body}} -> encode(body)
      {:error, reason} -> {:error, reason}
    end
  end

  defp encode(body) do
    case Image.from_binary(body) do
      {:ok, img} ->
        with {:ok, resized} <- Image.thumbnail(img, @max_dimension),
             {:ok, jpeg_binary} <- Image.write(resized, :memory, suffix: ".jpg", quality: 85) do
          {:ok, Base.encode64(jpeg_binary)}
        end

      {:error, _} ->
        {:error, :unsupported_format}
    end
  end
end
