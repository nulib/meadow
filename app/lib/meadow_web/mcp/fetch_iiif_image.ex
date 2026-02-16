defmodule MeadowWeb.MCP.FetchIIIFImage do
  @moduledoc """
  Fetch an image from an IIIF image information URI (ending with 'info.json')

  ## Example Usage

      %{
        base_url: "https://example.org/iiif/abcd1234/info.json"
      }
  """

  use Anubis.Server.Component,
    type: :tool,
    name: "fetch_iiif_image",
    mime_type: "application/json"

  alias Anubis.Server.Response
  alias Meadow.Utils.DCAPI
  require Logger

  @timeout 600_000

  schema do
    field(:base_url, :string,
      description: "The base URL of the IIIF image information (ending with 'info.json')",
      required: true
    )
  end

  def name, do: "fetch_iiif_image"

  @impl true
  def execute(%{base_url: base_url}, frame) do
    if String.ends_with?(base_url, "info.json") do
      Logger.info("Fetching IIIF image from #{base_url}")
      uri =
        URI.parse(base_url)
        |> URI.merge("full/!1024,1024/0/default.jpg")
        |> URI.to_string()

        {:ok, %{token: token}} =
          DCAPI.token(@timeout,
            scopes: ["read:Public", "read:Published", "read:Private", "read:Unpublished"],
            is_superuser: true
          )

      case Meadow.HTTP.get(uri, headers: [{"Authorization", "Bearer #{token}"}]) do
        {:ok, %Req.Response{status: 200, body: body}} ->
          {:reply, Response.tool() |> Response.image(Base.encode64(body), "image/jpeg"), frame}

        {:ok, %Req.Response{status: status_code}} ->
          Logger.error("Failed to fetch IIIF image from #{uri}: HTTP #{status_code}")
          {:reply, Response.tool() |> Response.error("Failed to fetch IIIF image: HTTP #{status_code}"), frame}

        {:error, error} ->
          Logger.error("Error fetching IIIF image from #{uri}: #{inspect(error)}")
          {:reply, Response.tool() |> Response.error("Error fetching IIIF image: #{inspect(error)}"), frame}
      end
    else
      {:reply, Response.tool() |> Response.error("Invalid IIIF image information URL"), frame}
    end
  rescue
    error -> MeadowWeb.MCP.Error.error_response(__MODULE__, frame, error)
  end
end
