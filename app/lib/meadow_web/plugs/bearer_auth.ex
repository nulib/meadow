defmodule MeadowWeb.Plugs.BearerAuth do
  @moduledoc """
  checks for superuser bearer token in the authorization header
  """
  import Plug.Conn

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _default) do
    case get_req_header(conn, "authorization") do
      [] ->
        conn
      ["Bearer " <> token] ->
        validate_dc_api_token(conn, token)

    end
  end

  def validate_dc_api_token(conn, token) do
    with api_config <- Application.get_env(:meadow, :dc_api)[:v2] do
      {:ok, token} = :jwt.decode(token, api_config["api_token_secret"])

      IO.inspect(token, label: "Decoded token")
      case token do
        %{"exp" => exp, "isSuperUser" => isSuperUser} ->
          current_time = DateTime.utc_now() |> DateTime.to_unix()

          if exp > current_time and isSuperUser do
            user = %Meadow.Accounts.User{
              id: token["sub"],
              email: token["email"],
              role: :editor,
              display_name: token["name"],
              username: token["sub"]
            }
            conn
            |> fetch_session()
            |> put_session(:current_user, user)
            |> configure_session(renew: true)


          else
            conn
            |> put_resp_content_type("application/json")
            |> resp(401, "Unauthorized - invalid claims")
            |> send_resp()
            |> halt()
          end

        _ ->
          conn
          |> put_resp_content_type("application/json")
          |> resp(401, "Unauthorized - invalid token")
          |> send_resp()
          |> halt()
      end

    end
  end
end
