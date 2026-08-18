defmodule Meadow.AWS.Error do
  @moduledoc """
  Raised when an AWS request fails and the caller wants an exception rather than
  an error tuple.
  """
  defexception [:message]
end

defmodule Meadow.AWS do
  @moduledoc """
  Builds `AWS.Client` structs for aws-elixir.

  Credentials come from `:aws_credentials`, which walks the standard AWS chain
  (application env, OS env, `~/.aws/credentials`, ECS task role, EKS pod identity,
  web identity, EC2 instance metadata) and refreshes them in the background before
  they expire. We deliberately build a fresh client on every request rather than
  caching one, so rotated credentials are always picked up.

  Requests go out through `Meadow.AWS.HTTPClient`, which uses `Meadow.HTTP` (Req over
  Finch) so AWS traffic shares Meadow's HTTP stack rather than pulling in a second one.

  Endpoints are resolved from `config :meadow, :aws`:

      config :meadow, :aws,
        endpoint: "localhost.localstack.cloud",
        proto: "https",
        port: 4566,
        services: %{lambda: [proto: "http", endpoint: "localhost", port: 3005]}

  With no `:endpoint` configured, the client keeps aws-elixir's defaults and talks
  to the real AWS endpoint for the service.
  """

  alias AWS.Client

  require Logger

  @default_region "us-east-1"

  @doc """
  Build a client for `service`.

  `service` selects a per-service override out of the `:services` map; anything
  without an override falls back to the top-level settings.
  """
  @spec client(atom()) :: Client.t()
  def client(service \\ :default) do
    %Client{http_client: {Meadow.AWS.HTTPClient, []}}
    |> apply_credentials(credentials())
    |> apply_endpoint(endpoint_config(service))
  end

  @doc """
  The current credentials as reported by `:aws_credentials`, or `nil` if none are
  available.

  The map uses the keys `:access_key_id`, `:secret_access_key`, `:token`, and
  `:region`; not every provider populates all of them.
  """
  @spec credentials() :: map() | nil
  def credentials do
    case :aws_credentials.get_credentials() do
      credentials when is_map(credentials) -> credentials
      _ -> nil
    end
  end

  @doc """
  The region Meadow should sign requests for.
  """
  @spec region() :: binary()
  def region do
    with nil <- credentials() |> region_from_credentials(),
         nil <- System.get_env("AWS_REGION"),
         nil <- System.get_env("AWS_DEFAULT_REGION") do
      Application.get_env(:meadow, :aws, []) |> Keyword.get(:region, @default_region)
    end
  end

  @doc """
  The scheme/host/port a client will actually talk to, as a URL with no path.

  Used where we have to build a URL by hand instead of going through a generated
  aws-elixir function: presigned URLs and the Bedrock event stream.
  """
  @spec endpoint_url(Client.t(), binary()) :: binary()
  def endpoint_url(%Client{} = client, host) do
    case {client.proto, client.port} do
      {"https", 443} -> "https://#{host}"
      {"http", 80} -> "http://#{host}"
      {proto, port} -> "#{proto}://#{host}:#{port}"
    end
  end

  @doc """
  The host a client will use for `service`, honoring any configured endpoint
  override and otherwise falling back to `<prefix>.<region>.amazonaws.com`.
  """
  @spec host(Client.t(), binary()) :: binary()
  def host(%Client{endpoint: endpoint}, _endpoint_prefix) when is_binary(endpoint), do: endpoint

  def host(%Client{region: region}, endpoint_prefix),
    do: "#{endpoint_prefix}.#{region}.#{Client.default_endpoint()}"

  defp region_from_credentials(%{region: region}) when is_binary(region), do: region
  defp region_from_credentials(_), do: nil

  defp apply_credentials(client, %{access_key_id: key, secret_access_key: secret} = credentials) do
    %{
      client
      | access_key_id: key,
        secret_access_key: secret,
        session_token: Map.get(credentials, :token),
        region: region()
    }
  end

  defp apply_credentials(client, _) do
    Logger.warning("No AWS credentials available. Proceeding with an unsigned client.")
    %{client | region: region()}
  end

  defp apply_endpoint(client, opts) do
    client = %{
      client
      | proto: Keyword.get(opts, :proto, client.proto),
        port: Keyword.get(opts, :port, client.port)
    }

    case Keyword.get(opts, :endpoint) do
      nil -> client
      endpoint -> Client.put_endpoint(client, endpoint)
    end
  end

  defp endpoint_config(service) do
    config = Application.get_env(:meadow, :aws, [])
    shared = Keyword.take(config, [:endpoint, :proto, :port])

    case config |> Keyword.get(:services, %{}) |> Map.get(service) do
      nil -> shared
      overrides -> Keyword.merge(shared, Enum.into(overrides, []))
    end
  end
end
