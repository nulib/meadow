defmodule MeadowWeb.Schema.Middleware.AssumeRole do
  @moduledoc """
  Checks if the current user can perform an action based on their role

  """
  @behaviour Absinthe.Middleware

  import Plug.Conn

  def call(%{value: %{new_role: role}} = resolution, _) do
    Map.update!(resolution, :context, fn context ->
      Map.put(context, :new_role, role)
    end)
    |> Map.update!(:value, fn %{new_role: role} ->
      %{message: "Role changed to: #{role}"}
    end)
  end

  def call(resolution, _) do
    resolution
  end

  def update_user_role(
        %{assigns: %{current_user: user}} = conn,
        %Absinthe.Blueprint{execution: %{context: %{new_role: new_role}}}
      )
      when not is_nil(user) do
    user = %{user | role: new_role}

    if new_role do
      conn
      |> fetch_session()
      |> assign(:current_user, user)
      |> put_session(:current_user, user)
      |> configure_session(renew: true)
    else
      conn
    end
  end

  def update_user_role(conn, _), do: conn
end
