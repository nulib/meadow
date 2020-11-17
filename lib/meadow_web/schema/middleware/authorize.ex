defmodule MeadowWeb.Schema.Middleware.Authorize do
  @moduledoc """
  Checks if the current user can perform an action based on their role

  """
  @behaviour Absinthe.Middleware

  def call(%{context: %{current_user: current_user}} = resolution, role) do
    if authorized_role?(current_user, role) do
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

  defp authorized_role?(%{}, :any), do: true
  defp authorized_role?(%{role: "Administrator"}, _role), do: true
  defp authorized_role?(%{role: "Manager"}, "Viewer"), do: true
  defp authorized_role?(%{role: "Manager"}, "Editor"), do: true
  defp authorized_role?(%{role: "Editor"}, "Viewer"), do: true
  defp authorized_role?(%{role: role}, role), do: true
  defp authorized_role?(_, _), do: false
end
