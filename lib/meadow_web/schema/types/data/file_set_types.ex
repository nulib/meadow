defmodule MeadowWeb.Schema.Data.FileSetTypes do
  @moduledoc """
  Absinthe Schema for FileSetTypes

  """
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Meadow.Data
  alias MeadowWeb.Resolvers
  alias MeadowWeb.Schema.Middleware

  object :file_set_queries do
    @desc "Get a list of file sets"
    field :file_sets, list_of(:file_set) do
      middleware(Middleware.Authenticate)
      resolve(&MeadowWeb.Resolvers.Data.file_sets/3)
    end
  end

  object :file_set_mutations do
    @desc "Create a new FileSet for a work"
    field :create_file_set, :file_set do
      arg(:accession_number, non_null(:string))
      arg(:role, non_null(:file_set_role))
      arg(:work_id, non_null(:id))
      arg(:metadata, non_null(:file_set_metadata_input))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Data.create_file_set/3)
    end

    @desc "Delete a FileSet"
    field :delete_file_set, :file_set do
      arg(:file_set_id, non_null(:id))
      middleware(Middleware.Authenticate)
      resolve(&Resolvers.Data.delete_file_set/3)
    end
  end

  #
  # Input Object Types
  #

  @desc "Same as `file_set_metadata`. This represents all metadata associated with a file_set. It is stored in a single json field."
  input_object :file_set_metadata_input do
    field :location, :string
    field :original_filename, :string
    field :description, :string
  end

  @desc "Input fields for a `file_set` object "
  input_object :file_set_input do
    field :accession_number, non_null(:string)
    field :role, non_null(:file_set_role)
    field :metadata, :file_set_metadata_input
  end

  #
  # Object Types
  #

  @desc "A `file_set` object represents one file (repository object in S3)"
  object :file_set do
    field :id, non_null(:id)
    field :accession_number, non_null(:string)
    field :role, non_null(:file_set_role)
    field :position, :string
    field :rank, :integer
    field :work, :work, resolve: dataloader(Data)
    field :metadata, :file_set_metadata
    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)
  end

  @desc "`file_set_metadata` represents all metadata associated with a file set object. It is stored in a single json field."
  object :file_set_metadata do
    field :location, :string
    field :original_filename, :string
    field :description, :string
    field :digests, :string
  end

  @desc "A `file_set_role` designates whether the file is an access or preservation master and will determine how the file is processed and stored."
  enum :file_set_role do
    value(:am, as: "am", description: "Access Master")
    value(:pm, as: "pm", description: "Preservaton Master")
  end
end
