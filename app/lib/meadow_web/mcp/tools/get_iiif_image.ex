defmodule MeadowWeb.MCP.Tools.GetIIIFImage do
  @moduledoc """
  Fetch an IIIF-ready image given a file set ID.

  This is the eval-safe image tool. Batch AI ingest should use get_ingest_image
  because those files are not IIIF-ready yet.
  """

  use Anubis.Server.Component,
    type: :tool,
    name: "get_iiif_image",
    mime_type: "image/jpeg"

  alias MeadowWeb.MCP.Tools.GetImage

  schema do
    field(:file_set_id, :string,
      description: "The ID of the IIIF-ready file set to fetch the image for",
      required: true
    )
  end

  @impl true
  def execute(params, frame), do: GetImage.execute(params, frame)
end
