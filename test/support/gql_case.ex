defmodule MeadowWeb.GQLCase do
  use ExUnit.CaseTemplate

  @moduledoc """
  This module defines some setup for testing GraphQL queries, mutations, and subscriptions
  """

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
