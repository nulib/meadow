defmodule MeadowWeb.Resolvers.Accounts do
  @moduledoc """
  Absinthe resolver for User and Group Management related functionality
  """

  def me(_, _, %{context: %{current_user: user}}) do
    {:ok, user}
  end

  def me(_, _, _) do
    {:ok, nil}
  end
end
