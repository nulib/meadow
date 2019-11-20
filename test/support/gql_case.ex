defmodule MeadowWeb.GQLCase do
  use ExUnit.CaseTemplate

  @moduledoc """
  This module defines some setup for testing GraphQL queries, mutations, and subscriptions
  """

  using do
    quote do
      use Wormwood.GQLCase
    end
  end

  setup do
    {:ok,
     gql_context: %{
       current_user: %{
         username: "user1",
         email: "email@example.com",
         display_name: "User Name"
       }
     }}
  end
end
