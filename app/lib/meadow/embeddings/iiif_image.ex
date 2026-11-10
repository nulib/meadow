defmodule Meadow.Embeddings.IIIFImage do
  @moduledoc """
  Fetches a file set's image from the IIIF server at the size the embedding
  model wants.

  The model resizes every image to a fixed pixel budget, so there is no point
  in moving the full-resolution file around. The image's dimensions are read
  from its `info.json` and the IIIF server is asked for exactly the model's
  target size, as lossless PNG. Images that are already smaller than the
  target are requested whole (the IIIF server does not upscale) and resized
  by `Meadow.Embeddings.ImageInput`.
  """

  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Embeddings.{Config, ImageInput}
  alias Meadow.HTTP
  alias Meadow.Utils.DCAPI

  @request_opts [redirect: true, receive_timeout: 60_000, raw: true]
  @scopes ["read:Public", "read:Published", "read:Private", "read:Unpublished"]

  @doc """
  Fetch the image for a file set. Returns `{:ok, binary}`,
  `{:error, :no_image}` when the file set has no IIIF image,
  `{:error, :invalid_image_info}` when its `info.json` cannot be used, or
  `{:error, {:http_error, status, body}}` / `{:error, reason}` when a request
  fails.
  """
  @spec fetch(FileSet.t()) :: {:ok, binary()} | {:error, term()}
  def fetch(%FileSet{} = file_set) do
    case FileSets.representative_image_url_for(file_set) do
      nil ->
        {:error, :no_image}

      base_url ->
        headers = headers()

        with {:ok, info} <- get(base_url <> "/info.json", headers),
             {:ok, %{"width" => width, "height" => height}} <- Jason.decode(info) do
          get(base_url <> "/" <> variant(height, width), headers)
        else
          {:error, %Jason.DecodeError{}} -> {:error, :invalid_image_info}
          {:ok, _info_without_dimensions} -> {:error, :invalid_image_info}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  @doc """
  The IIIF region/size/rotation/quality.format path for an image of the given
  dimensions.

      iex> Meadow.Embeddings.IIIFImage.variant(3015, 3000)
      "full/768,768/0/default.png"

      iex> Meadow.Embeddings.IIIFImage.variant(400, 300)
      "full/max/0/default.png"
  """
  def variant(height, width) do
    case ImageInput.target_size(height, width, Config.image_soft_tokens()) do
      {target_height, target_width} when target_height <= height and target_width <= width ->
        "full/#{target_width},#{target_height}/0/default.png"

      _ ->
        "full/max/0/default.png"
    end
  end

  defp get(url, headers) do
    opts = [{:headers, headers} | @request_opts] ++ Config.req_options()

    case HTTP.get(url, opts) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:ok, %{status: status, body: body}} -> {:error, {:http_error, status, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  # Unpublished and private works are embedded too, so the request carries
  # a short-lived superuser token, as the transcriber's does
  defp headers do
    case DCAPI.token(300, scopes: @scopes, is_superuser: true) do
      {:ok, %{token: token}} -> [{"authorization", "Bearer #{token}"}]
      _ -> []
    end
  end
end
