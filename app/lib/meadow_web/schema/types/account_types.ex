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

    @desc "Get the list of Roles"
    field :roles, list_of(:string) do
      middleware(Middleware.Authenticate)
      resolve(&MeadowWeb.Resolvers.Accounts.list_roles/3)
    end

    @desc "List all users with their roles"
    field :users, list_of(:user) do
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Administrator")
      resolve(&Resolvers.Accounts.list_users/3)
    end
  end

  object :account_mutations do
    @desc "Assume role"
    field :assume_role, :status_message do
      arg(:user_role, non_null(:user_role))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Administrator")
      resolve(&Resolvers.Accounts.assume_role/3)
      middleware(Middleware.AssumeRole)
    end

    @desc "Set user role"
    field :set_user_role, :status_message do
      arg(:user_id, non_null(:id))
      arg(:user_role, :user_role)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Administrator")
      resolve(&Resolvers.Accounts.set_user_role/3)
    end
  end

  @desc "A User Entry"
  object :entry do
    field :id, non_null(:id)
    field :name, :string
    field :type, :entry_type
  end

  object :user do
    field :username, non_null(:string)
    field :email, :string
    field :display_name, :string
    field :role, :user_role
    field :token, :string
  end

  object :status do
    field :message, non_null(:string)
  end

  @desc "Meadow user roles"
  enum :user_role do
    value(:superuser, description: "superuser")
    value(:administrator, description: "administrator")
    value(:manager, description: "manager")
    value(:editor, description: "editor")
    value(:user, description: "user")
  end

  @desc "work types"
  enum :entry_type do
    value(:group, as: "group", description: "group")
    value(:user, as: "user", description: "user")
  end
end
