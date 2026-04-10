defmodule MeadowWeb.MCP.Tools.SubmitAIPreviews do
  @moduledoc """
  Store AI-generated metadata previews for an ingest sheet.

  Called by the AI preview agent after analyzing ingest images and searching
  authorities. Stores structured preview data directly to the sheet's ai_preview
  field, bypassing the unreliable free-text JSON parsing approach.
  """

  use Anubis.Server.Component,
    type: :tool,
    mime_type: "application/json",
    description: "Store AI-generated metadata previews for an ingest sheet."

  alias Anubis.MCP.Error, as: MCPError
  alias Anubis.Server.Response
  alias Meadow.Ingest.Sheets
  require Logger

  @max_dimension 512

  @subject_schema %{
    id: :string,
    label: :string
  }

  @preview_schema %{
    work_accession_number: {:required, :string},
    filename: {:required, :string},
    description: {:required, :string},
    subjects: {:required, {:list, @subject_schema}}
  }

  schema do
    field(:sheet_id, :string,
      required: true,
      description: "UUID of the ingest sheet these previews belong to"
    )

    field(:previews, {:list, @preview_schema},
      required: true,
      description: """
      Array of preview objects, one per work. Each object must include:
        - work_accession_number (string): the work's accession number
        - filename (string): S3 URI of the representative image (e.g. s3://bucket/path/file.tif)
        - description (string): 1-3 sentence descriptive summary of the image
        - subjects (array): authority search results, each with "id" (URI) and "label" (string)
      """
    )
  end

  @impl true
  def execute(%{sheet_id: sheet_id, previews: previews}, frame) do
    Logger.info("SubmitAIPreviews: storing #{length(previews)} preview(s) for sheet #{sheet_id}")

    sheet = Sheets.get_ingest_sheet!(sheet_id)
    previews_with_thumbnails = Enum.map(previews, &add_thumbnail/1)

    case Sheets.update_ingest_sheet(sheet, %{ai_preview: previews_with_thumbnails}) do
      {:ok, _} ->
        {:reply, Response.tool() |> Response.structured(%{stored: length(previews)}), frame}

      {:error, reason} ->
        {:error, MCPError.execution(inspect(reason)), frame}
    end
  rescue
    error -> {:error, MCPError.protocol(:internal_error, %{error: inspect(error)}), frame}
  end

  defp add_thumbnail(%{filename: filename} = preview) do
    %URI{host: bucket, path: "/" <> key} = URI.parse(filename)

    case fetch_thumbnail(bucket, key) do
      {:ok, base64} ->
        Map.put(preview, :thumbnail, base64)

      {:error, reason} ->
        Logger.warning("SubmitAIPreviews: could not fetch thumbnail for #{filename}: #{inspect(reason)}")
        preview
    end
  end

  defp fetch_thumbnail(bucket, key) do
    case ExAws.S3.get_object(bucket, key) |> ExAws.request() do
      {:ok, %{body: body}} ->
        case Image.from_binary(body) do
          {:ok, img} ->
            with {:ok, resized} <- Image.thumbnail(img, @max_dimension),
                 {:ok, jpeg_binary} <- Image.write(resized, :memory, suffix: ".jpg", quality: 85) do
              {:ok, Base.encode64(jpeg_binary)}
            end

          {:error, _} ->
            {:error, :unsupported_format}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
