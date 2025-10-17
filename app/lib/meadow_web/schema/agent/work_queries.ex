defmodule MeadowWeb.Schema.Agent.WorkQueries do
  @moduledoc """
  Agent subset of work queries
  """
  use Absinthe.Schema.Notation
  alias MeadowWeb.Resolvers.Data
  alias MeadowWeb.Schema.Middleware

  object :agent_work_queries do
    @desc "Get a work by id"
    field :work, :work do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Data.work/3)
    end

    @desc "Get a list of works"
    field :works, list_of(:work) do
      arg(:limit, :integer, default_value: 100)
      arg(:filter, :work_filter)
      arg(:order, type: :sort_order, default_value: :asc)
      middleware(Middleware.Authenticate)
      resolve(&Data.works/3)
    end
  end
end
