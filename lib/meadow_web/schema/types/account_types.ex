defmodule MeadowWeb.Schema.AccountTypes do
  @moduledoc """
  Absinthe Schema for AccountTypes

  """
  use Absinthe.Schema.Notation

  object :user do
    field :username, non_null(:string)
    field :email, :string
    field :display_name, :string
  end
end
