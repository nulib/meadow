defmodule MeadowWeb.MCP.Tools.GetIngestImage do
  @moduledoc """
  Fetch and resize an image from the ingest S3 bucket by its S3 URI.
  Used by the AI preview agent to visually analyze ingest images before IIIF
  derivatives are available.
  """

  use Anubis.Server.Component,
    type: :tool,
    mime_type: "image/jpeg"

  alias Anubis.MCP.Error, as: MCPError
  alias Anubis.Server.Response
  require Logger

  @max_dimension 1024

  schema do
    field(:filename, :string,
      description: "S3 URI of the image file (e.g. s3://bucket/path/to/file.tif)",
      required: true
    )
  end

  @impl true
  def execute(%{filename: filename}, frame) do
    %URI{host: bucket, path: "/" <> key} = URI.parse(filename)

    case fetch_and_encode(bucket, key) do
      {:ok, base64} ->
        {:reply, Response.tool() |> Response.image(base64, "image/jpeg"), frame}

      {:error, :unsupported_format} ->
        Logger.warning("GetIngestImage: unsupported format for #{filename}")
        {:reply,
         Response.tool()
         |> Response.text("Image format not supported for preview (#{Path.extname(key)})"),
         frame}

      {:error, reason} ->
        Logger.error("GetIngestImage: failed to fetch #{filename}: #{inspect(reason)}")
        {:error, MCPError.resource(:not_found, %{id: filename}), frame}
    end
  end

  defp fetch_and_encode(bucket, key) do
    case ExAws.S3.get_object(bucket, key) |> ExAws.request() do
      {:ok, %{body: body}} ->
        resize_and_encode(body)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp resize_and_encode(binary) do
    case Image.from_binary(binary) do
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
