defmodule MeadowWeb.MCP.Tools.GetImage do
  @moduledoc """
  Fetch an image given a file set ID
  """

  use Anubis.Server.Component,
    type: :tool,
    mime_type: "image/jpeg"

  alias Anubis.MCP.Error, as: MCPError
  alias Anubis.Server.Response
  alias Meadow.Utils.DCAPI
  require Logger

  @timeout 600_000

  schema do
    field(:file_set_id, :string,
      description: "The ID of the file set to fetch the image for",
      required: true
    )
  end

  @impl true
  def execute(%{file_set_id: file_set_id}, frame) do
    uri =
      Meadow.Config.iiif_server_url()
      |> Path.join(file_set_id)
      |> Path.join("full/!1024,1024/0/default.jpg")

    {:ok, %{token: token}} =
      DCAPI.token(@timeout,
        scopes: ["read:Public", "read:Published", "read:Private", "read:Unpublished"],
        is_superuser: true
      )

    case Meadow.HTTP.get(uri, headers: [{"Authorization", "Bearer #{token}"}]) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:reply, Response.tool() |> Response.image(Base.encode64(body), "image/jpeg"), frame}

      {:ok, %Req.Response{status: 404}} ->
        Logger.error("Failed to fetch IIIF image from #{uri}: Not Found")
        {:error, MCPError.resource(:not_found, %{id: file_set_id}), frame}

      {:ok, %Req.Response{status: status_code}} ->
        Logger.error("Failed to fetch IIIF image from #{uri}: HTTP #{status_code}")
        {:reply, MCPError.protocol(:internal_error, %{id: file_set_id, error: "Failed to fetch IIIF image: HTTP #{status_code}"}), frame}

      {:error, error} ->
        Logger.error("Error fetching IIIF image from #{uri}: #{inspect(error)}")
        {:reply, MCPError.protocol(:internal_error, %{id: file_set_id, error: "Error fetching IIIF image: #{inspect(error)}"}), frame}
    end
  end
end
