defmodule MeadowWeb.Schema.NULAuthorityTypes do
  @moduledoc """
  GraphQL schema types for NUL AuthorityRecords
  """

  use Absinthe.Schema.Notation
  alias MeadowWeb.Resolvers
  alias MeadowWeb.Schema.Middleware

  object :nul_authority_queries do
    @desc "Get a list of NUL AuthorityRecords"
    field :nul_authority_records, list_of(:nul_authority_record) do
      arg(:limit, :integer, default_value: 100)
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.NULAuthorityRecords.nul_authority_records/3)
    end

    @desc "Get an NUL AuthorityRecord by ID"
    field :nul_authority_record, :nul_authority_record do
      arg(:id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.NULAuthorityRecords.nul_authority_record/3)
    end
  end

  object :nul_authority_mutations do
    @desc "Create a new NUL AuthorityRecord"
    field :create_nul_authority_record, :nul_authority_record do
      arg(:label, non_null(:string))
      arg(:hint, :string)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Manager")
      resolve(&Resolvers.NULAuthorityRecords.create_nul_authority_record/3)
    end

    @desc "Update an NUL AuthorityRecord"
    field :update_nul_authority_record, :nul_authority_record do
      arg(:id, non_null(:id))
      arg(:label, non_null(:string))
      arg(:hint, :string)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Manager")
      resolve(&Resolvers.NULAuthorityRecords.update_nul_authority_record/3)
    end

    @desc "Delete an AuthorityRecord"
    field :delete_nul_authority_record, :nul_authority_record do
      arg(:nul_authority_record_id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.NULAuthorityRecords.delete_nul_authority_record/3)
    end
  end

  #
  # Object Types
  #

  object :nul_authority_record do
    field :id, non_null(:id)
    field :label, non_null(:string)
    field :hint, :string
  end
end
