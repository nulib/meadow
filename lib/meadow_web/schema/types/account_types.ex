defmodule MeadowWeb.Schema.AccountTypes do
  @moduledoc """
  Absinthe Schema for AccountTypes

  """
  use Absinthe.Schema.Notation
  alias MeadowWeb.Resolvers

  object :account_queries do
    @desc "Get the currently signed-in user"
    field :me, :user do
      resolve(&Resolvers.Accounts.me/3)
    end
  end

  object :user do
    field :username, non_null(:string)
    field :email, :string
    field :display_name, :string
  end
end
