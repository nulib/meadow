defmodule MeadowLivebookAuth do
  @moduledoc """
  Custom authentication module for Livebook that passes an existing Meadow
  session cookie to Meadow's GraphQL endpoint to find out if the current
  user is a Meadow SuperUser. Only works if Livebook and Meadow are running
  on the same hostname.
  """
  use GenServer

  @query "query { me { displayName email role username } }"

  @spec start_link(keyword) :: {:ok, pid()}
  def start_link(opts) do
    identity_key = opts[:identity_key]
    GenServer.start_link(__MODULE__, identity_key, Keyword.take(opts, [:name]))
  end

  def init(init_arg) do
    Application.put_env(:livebook, :authentication_mode, :disabled)
    {:ok, init_arg}
  end

  @spec authenticate(GenServer.server(), Plug.Conn.t(), keyword()) ::
          {Plug.Conn.t(), map() | nil}
  def authenticate(server, conn, _) do
    System.get_env("MEADOW_LIVEBOOK_BUCKET")
    |> attach_storage()

    with url <- find_meadow_url(server),
         user <- meadow_auth(url, conn) do
      {conn, user}
    end
  end

  defp find_meadow_url(server) do
    case get_state(server) do
      %{auth_url: auth_url} ->
        auth_url

      _ ->
        with url <- get_meadow_url() do
          set_state(server, :auth_url, url)
          url
        end
    end
  end

  defp get_meadow_url do
    with base <- System.get_env("MEADOW_URL") |> get_meadow_url() do
      Path.join(base, "api/graphql")
    end
  end

  defp get_meadow_url(nil) do
    with [_ | [host | _]] <- Node.self() |> to_string() |> String.split("@") do
      "http://#{host}:4000/"
    end
  end

  defp get_meadow_url(url), do: url

  defp meadow_auth(nil, _), do: nil

  defp meadow_auth(url, conn) do
    with meadow_cookie <-
           conn |> Plug.Conn.fetch_cookies() |> Map.get(:cookies) |> Map.get("_meadow_key") do
      Req.post(url,
        body: @query,
        headers: ["Content-Type": "application/graphql", Cookie: "_meadow_key=#{meadow_cookie}"]
      )
      |> process_auth_response()
    end
  end

  defp process_auth_response(
         {:ok, %{status: 200, body: %{"data" => %{"me" => %{"role" => "SUPERUSER"} = user}}}}
       ) do
    %{id: user["username"], name: user["displayName"], email: user["email"]}
  end

  defp process_auth_response(_), do: nil

  def get_state(server) do
    case :sys.get_state(server) do
      nil -> %{}
      map -> map
    end
  end

  def set_state(server, key, value) do
    :sys.replace_state(server, fn
      nil -> %{key => value}
      map -> Map.put(map, key, value)
    end)
  end

  defp attach_storage(bucket) when is_binary(bucket) and byte_size(bucket) > 0 do
    url = "https://s3.amazonaws.com/#{bucket}"

    Livebook.Hubs.get_file_systems()
    |> Enum.any?(fn
      %Livebook.FileSystem.S3{bucket_url: ^url} -> true
      _ -> false
    end)
    |> attach_s3_storage(url)
  end

  defp attach_storage(_), do: :noop

  defp attach_s3_storage(true, _), do: :noop

  defp attach_s3_storage(false, url) do
    hash = :crypto.hash(:sha256, url)
    encrypted_hash = "s3-" <> Base.url_encode64(hash, padding: false)

    [hub | _] = Livebook.Hubs.get_hubs()

    file_system = %Livebook.FileSystem.S3{
      id: encrypted_hash,
      bucket_url: url,
      external_id: nil,
      region: Livebook.FileSystem.S3.region_from_url(url),
      access_key_id: nil,
      secret_access_key: nil,
      hub_id: "personal-hub"
    }

    Livebook.Hubs.create_file_system(hub, file_system)
  end
end
