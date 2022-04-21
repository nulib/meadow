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
    field :roles, list_of(:entry) do
      middleware(Middleware.Authenticate)
      resolve(&MeadowWeb.Resolvers.Accounts.list_roles/3)
    end

    @desc "Get a list of members of a role"
    field :role_members, list_of(:entry) do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Accounts.role_members/3)
    end

    @desc "Get a list of members of a group"
    field :group_members, list_of(:entry) do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Accounts.group_members/3)
    end
  end

  object :account_mutations do
    @desc "Add a group to a role"
    field :add_group_to_role, :status_message do
      arg(:group_id, non_null(:id))
      arg(:role_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Accounts.add_group_to_role/3)
    end

    @desc "Assume role"
    field :assume_role, :status_message do
      arg(:user_role, non_null(:user_role))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Administrator")
      resolve(&Resolvers.Accounts.assume_role/3)
    end
  end

  @desc "An LDAP Entry"
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
    value(:administrator, as: "Administrator", description: "administrator")
    value(:manager, as: "Manager", description: "manager")
    value(:editor, as: "Editor", description: "editor")
    value(:user, as: "User", description: "user")
  end

  @desc "work types"
  enum :entry_type do
    value(:group, as: "group", description: "group")
    value(:user, as: "user", description: "user")
  end
end
