defmodule MeadowWeb.Schema.AccountTypes do
  @moduledoc """
  Absinthe Schema for AccountTypes

  """
  use Absinthe.Schema.Notation
  alias MeadowWeb.Resolvers
  alias MeadowWeb.Schema.Middleware

  object :account_queries do
    @desc "Get the currently signed-in user"
    field :me, :user do
      resolve(&Resolvers.Accounts.me/3)
    end

    @desc "Get a list of Groups"
    field :groups, list_of(:group) do
      middleware(Middleware.Authenticate)
      resolve(&MeadowWeb.Resolvers.Accounts.list_groups/3)
    end

    @desc "Get a list of members of a group"
    field :group_members, list_of(:user) do
      arg(:group_name, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Accounts.group_members/3)
    end

    @desc "Get a list of groups a user is a member of"
    field :user_groups, list_of(:group) do
      arg(:username, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Accounts.user_groups/3)
    end
  end

  object :user do
    field :username, non_null(:string)
    field :email, :string
    field :display_name, :string
  end

  object :group do
    field :name, non_null(:string)
  end
end
