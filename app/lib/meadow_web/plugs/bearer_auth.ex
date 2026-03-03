defmodule MeadowWeb.Plugs.BearerAuth do
  @moduledoc """
  checks for superuser bearer token in the authorization header
  """
  import Plug.Conn

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _default) do
    get_req_header(conn, "authorization")
    |> validate_auth_header(conn)
  end

  defp validate_auth_header([], conn), do: conn
  defp validate_auth_header(["Bearer " <> token], conn), do: validate_jwt(conn, token)

  defp validate_jwt(conn, token) do
    api_config = Application.get_env(:meadow, :dc_api)[:v2]
    :jwt.decode(token, api_config["api_token_secret"])
    |> validate_decoded_token(conn)
  end

  defp validate_decoded_token({:ok, %{"isSuperUser" => true} = token}, conn),
    do: add_user_to_session(token, conn)

  defp validate_decoded_token({:ok, %{"scopes" => scopes} = token}, conn) when is_list(scopes) do
    if Enum.any?(scopes, &String.starts_with?(&1, "meadow:")),
      do: add_user_to_session(token, conn),
      else: conn
  end

  defp validate_decoded_token(_, conn), do: conn

  defp add_user_to_session(token, conn) do
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
  end
end
