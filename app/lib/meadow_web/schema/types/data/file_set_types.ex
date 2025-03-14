defmodule MeadowWeb.Schema.Data.FileSetTypes do
  @moduledoc """
  Absinthe Schema for FileSetTypes

  """
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Meadow.Data
  alias Meadow.Data.FileSets
  alias Meadow.Utils.ExtractedMetadata
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
    @desc "Ingests a new FileSet for a work"
    field :ingest_file_set, :file_set do
      arg(:accession_number, non_null(:string))
      arg(:role, non_null(:coded_term_input))
      arg(:work_id, non_null(:id))
      arg(:core_metadata, non_null(:file_set_core_metadata_input))
      arg(:structural_metadata, :file_set_structural_metadata_input)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Data.ingest_file_set/3)
    end

    @desc "Update a FileSet's metadata"
    field :update_file_set, :file_set do
      arg(:id, non_null(:id))
      arg(:poster_offset, :integer)
      arg(:core_metadata, :file_set_core_metadata_update)
      arg(:structural_metadata, :file_set_structural_metadata_input)
      arg(:group_with, :id)
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Data.update_file_set/3)
    end

    @desc "Replace file set (create new version)"
    field :replace_file_set, :file_set do
      arg(:id, non_null(:id))
      arg(:core_metadata, non_null(:file_set_core_metadata_input))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Data.replace_file_set/3)
    end

    @desc "Update metadata for a list of fileSets"
    field :update_file_sets, list_of(:file_set) do
      arg(:file_sets, non_null(list_of(:file_set_update)))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Data.update_file_sets/3)
    end

    @desc "Delete a FileSet"
    field :delete_file_set, :file_set do
      arg(:file_set_id, non_null(:id))
      middleware(Middleware.Authenticate)
      middleware(Middleware.Authorize, "Editor")
      resolve(&Resolvers.Data.delete_file_set/3)
    end
  end

  #
  # Input Object Types
  #

  @desc "Same as `file_set_core_metadata`. This represents all metadata associated with a file_set accepted on creation. It is stored in a single json field."
  input_object :file_set_core_metadata_input do
    field(:label, :string)
    field(:location, :string)
    field(:original_filename, :string)
    field(:description, :string)
  end

  @desc "Same as `file_set_core_metadata`. This represents all updatable metadata associated with a file_set. It is stored in a single json field."
  input_object :file_set_update do
    field(:id, non_null(:id))
    field(:core_metadata, :file_set_core_metadata_update)
    field(:structural_metadata, :file_set_structural_metadata_input)
  end

  @desc "Same as `file_set_core_metadata`. This represents all updatable metadata associated with a file_set. It is stored in a single json field."
  input_object :file_set_core_metadata_update do
    field(:label, :string)
    field(:description, :string)
  end

  @desc "Input fields for a `file_set` creation object "
  input_object :file_set_input do
    field(:accession_number, non_null(:string))
    field(:role, non_null(:coded_term_input))
    field(:core_metadata, :file_set_core_metadata_input)
  end

  @desc "Input fields for `file_set_structural_metadata`."
  input_object :file_set_structural_metadata_input do
    field(:type, :structural_metadata_type)
    field(:value, :string)
  end

  #
  # Object Types
  #

  @desc "A `file_set` object represents one file (repository object in S3)"
  object :file_set do
    field(:id, non_null(:id))
    field(:accession_number, non_null(:string))
    field(:role, non_null(:coded_term))
    field(:position, :string)
    field(:rank, :integer)
    field(:work, :work, resolve: dataloader(Data))
    field(:core_metadata, :file_set_core_metadata)
    field(:poster_offset, :integer)
    field(:group_with, :id)

    field :streaming_url, :string do
      resolve(fn file_set, _, _ ->
        {:ok, FileSets.distribution_streaming_uri_for(file_set)}
      end)
    end

    field :representative_image_url, :string do
      resolve(fn file_set, _, _ ->
        {:ok, FileSets.representative_image_url_for(file_set)}
      end)
    end

    field :extracted_metadata, :string do
      resolve(fn file_set, _, _ ->
        case file_set |> Map.get(:extracted_metadata) do
          nil -> {:ok, nil}
          value -> ExtractedMetadata.transform(value) |> Jason.encode()
        end
      end)
    end

    field(:structural_metadata, :file_set_structural_metadata)
    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end

  @desc "`file_set_core_metadata` represents all metadata associated with a file set object. It is stored in a single json field."
  object :file_set_core_metadata do
    field(:location, :string)
    field(:label, :string)
    field(:mime_type, :string)
    field(:original_filename, :string)
    field(:description, :string)
    field(:digests, :digests)
  end

  @desc "`digests` represents the possible digest hashes for a file set."
  object :digests do
    field(:md5, :string, do: resolve(fn digests, _, _ -> {:ok, Map.get(digests, "md5")} end))
    field(:sha1, :string, do: resolve(fn digests, _, _ -> {:ok, Map.get(digests, "sha1")} end))

    field(:sha256, :string,
      do: resolve(fn digests, _, _ -> {:ok, Map.get(digests, "sha256")} end)
    )
  end

  @desc "`file_set_structural_metadata` represents the structural metadata within a file set object."
  object :file_set_structural_metadata do
    field(:type, :structural_metadata_type)
    field(:value, :string)
  end

  @desc "accepted types for structural metadata"
  enum :structural_metadata_type do
    value(:webvtt, as: "webvtt", description: "Web VTT")
  end
end
