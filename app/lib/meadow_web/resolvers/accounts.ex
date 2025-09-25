defmodule MeadowWeb.Resolvers.Accounts do
  @moduledoc """
  Absinthe resolver for User and Group Management related functionality
  """
  alias Meadow.Accounts
  alias Meadow.Accounts.User

  def me(_, _, %{context: %{current_user: user} = context}) when not is_nil(user) do
    {:ok, Map.put(user, :token, Map.get(context, :auth_token))}
  end

  def me(_, _, _) do
    {:ok, nil}
  end

  def list_roles(_, _, _) do
    {:ok, Accounts.list_roles()}
  end

  def list_users(_, _, _) do
    {:ok,
     Accounts.list_users()
     |> Enum.map(fn user ->
       case User.find(user.id) do
         nil ->
           %User{
             id: user.id,
             username: user.id,
             email: "",
             display_name: "",
             role: user.role
           }

         found ->
           found
       end
     end)}
  end

  def assume_role(_, %{user_role: user_role}, _) do
    {:ok, %{new_role: user_role}}
  end

  def set_user_role(_, %{user_id: user_id, user_role: user_role}, _) do
    case Accounts.set_user_role(user_id, user_role) do
      {:ok, _} ->
        {:ok, %{message: update_message(user_id, user_role)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp update_message(user_id, nil), do: "Removed user role for #{user_id}"

  defp update_message(user_id, user_role),
    do: "User role updated successfully for #{user_id} to #{user_role}"
end
