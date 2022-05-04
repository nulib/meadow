defmodule MeadowWeb.Schema.Data.PreservationCheckTypes do
  @moduledoc """
  Absinthe Schema for Preservation Check Functionality

  """
  use Absinthe.Schema.Notation
  alias MeadowWeb.Resolvers.Data.PreservationChecks
  alias MeadowWeb.Schema.Middleware

  object :preservation_check_queries do
    @desc "Get all preservation checks"
    field :preservation_checks, list_of(:preservation_check) do
      arg(:limit, :integer, default_value: 100)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&PreservationChecks.preservation_checks/3)
    end
  end

  #
  # Object Types
  #

  @desc "Fields for a `preservation_check` object "
  object :preservation_check do
    field :id, :id
    field :status, :string
    field :filename, :string
    field :invalid_rows, :integer
    field :location, :string
    field :inserted_at, :datetime
    field :updated_at, :datetime
  end
end
