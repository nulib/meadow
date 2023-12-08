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
    with [_ | [host | _]] <- Node.self() |> to_string() |> String.split("@"),
         url <- "http://#{host}:4000/api/graphql" do
      set_state(server, :auth_url, url)
      {conn, meadow_auth(url, conn)}
    end
  end

  defp meadow_auth(nil, _), do: nil

  defp meadow_auth(url, conn) do
    with meadow_cookie <-
           conn |> Plug.Conn.fetch_cookies() |> Map.get(:cookies) |> Map.get("_meadow_key") do
      Req.get(url,
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
end
