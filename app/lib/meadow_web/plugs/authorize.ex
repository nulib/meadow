defmodule MeadowWeb.Plugs.Authorize do
  @moduledoc """
  A plug to authorize access to certain routes based on user roles.
  """

  import Meadow.Roles, only: [authorized?: 2]
  import Plug.Conn
  require Logger

  def init(opts) do
    {forward_plug, forward_opts} =
      case Keyword.get(opts, :forward_to) do
        {plug, opts} -> {plug, opts}
        plug -> {plug, []}
      end

    Keyword.put(opts, :forward_to, {forward_plug, forward_opts})
  end

  def call(conn, opts) do
    current_user = conn.assigns[:current_user]
    required_role = Keyword.get(opts, :require)
    Logger.debug("Authorizing user #{inspect(current_user)} for role #{inspect(required_role)}")

    if authorized?(current_user, required_role) do
      {forward_plug, forward_opts} = Keyword.get(opts, :forward_to)
      forward_plug.call(conn, forward_plug.init(forward_opts))
    else
      conn
      |> send_resp(401, "Unauthorized")
      |> halt()
    end
  end
end
