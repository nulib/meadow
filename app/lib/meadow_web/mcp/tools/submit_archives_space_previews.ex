defmodule MeadowWeb.MCP.Tools.SubmitArchivesSpacePreviews do
  @moduledoc """
  Store AI-generated metadata previews for an ArchivesSpace import.

  The ArchivesSpace counterpart to `SubmitAIPreviews`. There is no ingest
  sheet to write to here — the import preview is generated on demand for the
  import modal — so previews are keyed by a one-off token and written to
  `Meadow.ArchivesSpace.PreviewStore`, where the resolver that launched the
  agent reads them back out.
  """

  use Anubis.Server.Component,
    type: :tool,
    mime_type: "application/json",
    description: "Store AI-generated metadata previews for an ArchivesSpace import."

  alias Anubis.MCP.Error, as: MCPError
  alias Anubis.Server.Response
  alias Meadow.ArchivesSpace.PreviewStore
  alias MeadowWeb.MCP.Tools.PreviewThumbnail
  require Logger

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
    field(:token, :string,
      required: true,
      description: "Opaque token identifying the import preview these results belong to"
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
  def execute(%{token: token, previews: previews}, frame) do
    Logger.info(
      "SubmitArchivesSpacePreviews: storing #{length(previews)} preview(s) for token #{token}"
    )

    previews_with_thumbnails = Enum.map(previews, &PreviewThumbnail.add/1)
    PreviewStore.put(token, previews_with_thumbnails)

    {:reply, Response.tool() |> Response.structured(%{stored: length(previews)}), frame}
  rescue
    error -> {:error, MCPError.protocol(:internal_error, %{error: inspect(error)}), frame}
  end
end
