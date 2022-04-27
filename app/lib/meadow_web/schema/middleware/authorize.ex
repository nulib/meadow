defmodule MeadowWeb.Schema.Middleware.Authorize do
  @moduledoc """
  Checks if the current user can perform an action based on their role

  """
  @behaviour Absinthe.Middleware

  alias Meadow.Roles

  def call(%{context: %{current_user: current_user}} = resolution, role) do
    if Roles.authorized?(current_user, role) do
      resolution
    else
      resolution
      |> Absinthe.Resolution.put_result({:error, %{message: "Forbidden", status: 403}})
    end
  end

  def call(resolution, _role) do
    resolution
    |> Absinthe.Resolution.put_result({:error, %{message: "Forbidden", status: 403}})
  end
end
