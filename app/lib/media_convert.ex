defmodule MediaConvert do
  @moduledoc """
  Provides functionality for the AWS Elemental MediaConvert API
  """

  alias Meadow.AWS.Response

  require Logger

  @doc """
  Discover this account's MediaConvert endpoint and cache it as the `:mediaconvert`
  service override, so subsequent clients talk to it directly.

  MediaConvert is one of the few AWS services with an account-specific endpoint. When an
  endpoint is already configured — as it is when pointing at Localstack — discovery is
  skipped.
  """
  def configure! do
    if configured_endpoint() do
      :ok
    else
      with %URI{host: host} <- get_endpoint() |> URI.parse() do
        put_service_endpoint(host)
      end
    end
  end

  @doc """
  Create a MediaConvert job, returning its id.
  """
  def create_job(template) do
    configure!()

    Meadow.AWS.client(:mediaconvert)
    |> AWS.MediaConvert.create_job(template)
    |> case do
      {:ok, %{"job" => %{"id" => id}}, _response} -> {:ok, id}
      other -> Response.unwrap(other)
    end
  end

  defp get_endpoint do
    Meadow.AWS.client(:mediaconvert)
    |> AWS.MediaConvert.describe_endpoints(%{})
    |> case do
      {:ok, %{"endpoints" => [%{"url" => url} | _]}, _response} ->
        url

      other ->
        raise Meadow.AWS.Error,
          message: "Unable to discover the MediaConvert endpoint: #{inspect(other)}"
    end
  end

  # Any configured endpoint counts, whether it came from the shared `:endpoint` (as with
  # Localstack) or from a `:mediaconvert` override we cached on a previous call.
  defp configured_endpoint, do: Meadow.AWS.client(:mediaconvert).endpoint

  defp put_service_endpoint(host) do
    Logger.info("Using MediaConvert endpoint #{host}")

    config = Application.get_env(:meadow, :aws, [])
    services = Keyword.get(config, :services, %{})

    Application.put_env(
      :meadow,
      :aws,
      Keyword.put(config, :services, Map.put(services, :mediaconvert, endpoint: host))
    )
  end
end
