defmodule Meadow.Data.Schemas.Work do
  @moduledoc """
  A repository data object. Embeds one Metadata map and many FileSets.
  """

  use Ecto.Schema
  alias Meadow.Data.Schemas.ActionState
  alias Meadow.Data.Schemas.Batch
  alias Meadow.Data.Schemas.Collection
  alias Meadow.Data.Schemas.CSV.MetadataUpdateJob
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Data.Schemas.WorkAdministrativeMetadata
  alias Meadow.Data.Schemas.WorkDescriptiveMetadata
  alias Meadow.Data.Types
  alias Meadow.Ingest.Schemas.Sheet

  import Ecto.Changeset
  import Ecto.Query, warn: false
  import Meadow.Data.Schemas.Validations

  use Meadow.Constants

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "works" do
    field(:accession_number, :string)
    field(:published, :boolean, default: false)
    field(:visibility, Types.CodedTerm)
    field(:work_type, Types.CodedTerm)

    timestamps()

    embeds_one(:descriptive_metadata, WorkDescriptiveMetadata, on_replace: :update)
    embeds_one(:administrative_metadata, WorkAdministrativeMetadata, on_replace: :update)

    has_many(:file_sets, FileSet)

    has_many(:action_states, ActionState,
      references: :id,
      foreign_key: :object_id,
      on_delete: :delete_all
    )

    belongs_to(:collection, Collection)

    belongs_to(:ingest_sheet, Sheet)
    has_one(:project, through: [:ingest_sheet, :project])

    belongs_to(:representative_file_set, FileSet, on_replace: :nilify)

    field(:representative_image, :string, virtual: true, default: nil)

    many_to_many(
      :batches,
      Batch,
      join_through: "works_batches",
      on_replace: :delete
    )

    many_to_many(
      :metadata_update_jobs,
      MetadataUpdateJob,
      join_through: "works_metadata_update_jobs",
      on_replace: :delete
    )
  end

  defp changeset_params do
    {[:accession_number],
     [
       :collection_id,
       :representative_file_set_id,
       :ingest_sheet_id,
       :visibility,
       :work_type
     ]}
  end

  def changeset(work, attrs) do
    with {required_params, optional_params} <- changeset_params() do
      work
      |> cast(attrs, required_params ++ optional_params)
      |> prepare_embed(:administrative_metadata)
      |> prepare_embed(:descriptive_metadata)
      |> cast_embed(:administrative_metadata)
      |> cast_embed(:descriptive_metadata)
      |> cast_assoc(:file_sets)
      |> assoc_constraint(:collection)
      |> assoc_constraint(:representative_file_set)
      |> validate_required(required_params)
      |> unique_constraint(:accession_number)
    end
  end

  def migration_changeset(work \\ %__MODULE__{}, attrs) do
    with {required_params, optional_params} <- changeset_params() do
      required_params = [:id | required_params]

      work
      |> cast(attrs, required_params ++ optional_params)
      |> prepare_embed(:administrative_metadata)
      |> prepare_embed(:descriptive_metadata)
      |> cast_embed(:administrative_metadata)
      |> cast_embed(:descriptive_metadata)
      |> cast_assoc(:file_sets, with: &FileSet.migration_changeset/2)
      |> assoc_constraint(:collection)
      |> validate_required(required_params)
      |> unique_constraint(:accession_number)
    end
  end

  def update_timestamp(work, timestamp \\ NaiveDateTime.utc_now()) do
    cast(work, %{updated_at: timestamp}, [:updated_at])
  end

  def update_changeset(work, attrs \\ %{}) do
    allowed_params = [
      :collection_id,
      :ingest_sheet_id,
      :published,
      :representative_file_set_id,
      :visibility
    ]

    work
    |> cast(attrs, allowed_params)
    |> prepare_embed(:administrative_metadata)
    |> prepare_embed(:descriptive_metadata)
    |> cast_embed(:administrative_metadata)
    |> cast_embed(:descriptive_metadata)
    |> assoc_constraint(:collection)
    |> assoc_constraint(:representative_file_set)
  end

  def required_index_preloads do
    [
      :collection,
      :file_sets,
      :ingest_sheet,
      :project,
      :batches,
      :metadata_update_jobs,
      :representative_file_set
    ]
  end
end
