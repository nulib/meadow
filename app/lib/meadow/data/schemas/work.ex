defmodule Meadow.Data.Schemas.Work do
  @moduledoc """
  A repository data object. Has one descriptive and one administrative
  metadata row (with their repeating child rows) and many FileSets.
  """

  use Ecto.Schema
  alias Meadow.Data.Schemas.ActionState
  alias Meadow.Data.Schemas.ArkCache
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

    field(:visibility, Types.CodedTerm,
      scheme: "visibility",
      default: %{id: "RESTRICTED", scheme: "visibility", label: "Private"}
    )

    field(:work_type, Types.CodedTerm, scheme: "work_type")

    field(:behavior, Types.CodedTerm, scheme: "behavior")

    field(:ark, :string)

    timestamps()

    has_one(:descriptive_metadata, WorkDescriptiveMetadata, on_replace: :update)
    has_one(:administrative_metadata, WorkAdministrativeMetadata, on_replace: :update)

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

    belongs_to(:cached_ark, ArkCache, foreign_key: :ark, references: :ark, define_field: false)
  end

  defp changeset_params do
    {[:accession_number],
     [
       :ark,
       :collection_id,
       :ingest_sheet_id,
       :published,
       :representative_file_set_id,
       :visibility,
       :work_type,
       :behavior
     ]}
  end

  def changeset(work, attrs) do
    with {required_params, optional_params} <- changeset_params() do
      work
      |> preload_metadata()
      |> cast(attrs, required_params ++ optional_params)
      |> validate_trimmed(:accession_number)
      |> prepare_assoc(:administrative_metadata)
      |> prepare_assoc(:descriptive_metadata)
      |> cast_assoc(:administrative_metadata)
      |> cast_assoc(:descriptive_metadata)
      |> cast_assoc(:file_sets)
      |> assoc_constraint(:collection)
      |> assoc_constraint(:representative_file_set)
      |> validate_required(required_params)
      |> unique_constraint(:accession_number)
    end
  end

  def update_timestamp(work, timestamp \\ NaiveDateTime.utc_now()) do
    cast(work, %{updated_at: timestamp}, [:updated_at])
  end

  def update_changeset(work, attrs \\ %{}) do
    allowed_params = [
      :ark,
      :collection_id,
      :ingest_sheet_id,
      :published,
      :representative_file_set_id,
      :visibility,
      :behavior
    ]

    work
    |> preload_metadata()
    |> cast(attrs, allowed_params)
    |> prepare_assoc(:administrative_metadata)
    |> prepare_assoc(:descriptive_metadata)
    |> cast_assoc(:administrative_metadata)
    |> cast_assoc(:descriptive_metadata)
    |> assoc_constraint(:collection)
    |> assoc_constraint(:representative_file_set)
  end

  @doc """
  Nested preload list for the metadata rows and all their repeating child rows.
  Every read that touches `descriptive_metadata`/`administrative_metadata` must
  preload this (or go through `Meadow.Data.Works`, which does).
  """
  def metadata_preloads do
    [
      descriptive_metadata: WorkDescriptiveMetadata.repeating_fields(),
      administrative_metadata: WorkAdministrativeMetadata.repeating_fields()
    ]
  end

  @doc """
  Preload the metadata associations of a persisted work. Associations that are
  already loaded are skipped by `Repo.preload`, so this is cheap to call on a
  fully loaded work and only fills in what is missing (for example the child
  lists that were not part of an insert).
  """
  def preload_metadata(%__MODULE__{__meta__: %{state: :loaded}} = work) do
    case missing_metadata_preloads(work) do
      [] -> work
      preloads -> Meadow.Repo.preload(work, preloads)
    end
  end

  def preload_metadata(work), do: work

  # Only the associations that are actually `NotLoaded`; anything else (loaded
  # lists, or values a caller deliberately substituted) is left untouched
  defp missing_metadata_preloads(work) do
    Enum.flat_map(metadata_preloads(), fn {assoc, children} ->
      case Map.get(work, assoc) do
        %Ecto.Association.NotLoaded{} -> [{assoc, children}]
        %{} = metadata -> missing_children(assoc, metadata, children)
        _ -> []
      end
    end)
  end

  defp missing_children(assoc, metadata, children) do
    case Enum.filter(children, &match?(%Ecto.Association.NotLoaded{}, Map.get(metadata, &1))) do
      [] -> []
      missing -> [{assoc, missing}]
    end
  end

  def required_index_preloads do
    [
      :collection,
      {:file_sets, FileSet.metadata_preloads()},
      :ingest_sheet,
      :project,
      :batches,
      :metadata_update_jobs,
      :representative_file_set
    ] ++ metadata_preloads()
  end
end
