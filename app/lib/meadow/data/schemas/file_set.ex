defmodule Meadow.Data.Schemas.FileSet do
  @moduledoc """
  FileSets are used to describe objects stored in Amazon S3
  """
  use Ecto.Schema

  alias Meadow.Data.Schemas.{
    ActionState,
    FileSetAnnotation,
    FileSetCoreMetadata,
    FileSetDerivative,
    FileSetExtractedMetadata,
    FileSetStructuralMetadata,
    MultiValued,
    Work
  }

  alias Meadow.Data.Types

  import Ecto.Changeset
  import EctoRanked
  import Meadow.Data.Schemas.Validations

  use Meadow.Constants

  require Logger

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "file_sets" do
    field(:accession_number)
    field(:role, Types.CodedTerm, scheme: "file_set_role")
    field(:rank, :integer)
    field(:position, :any, virtual: true)
    field(:poster_offset, :integer)

    has_one(:core_metadata, FileSetCoreMetadata, on_replace: :update)
    has_one(:structural_metadata, FileSetStructuralMetadata, on_replace: :delete)
    has_many(:derivatives, FileSetDerivative, on_replace: :delete, preload_order: [asc: :kind])

    has_many(:extracted_metadata, FileSetExtractedMetadata,
      on_replace: :delete,
      preload_order: [asc: :tool]
    )

    timestamps()

    belongs_to(:work, Work)

    has_many(:action_states, ActionState,
      references: :id,
      foreign_key: :object_id,
      on_delete: :delete_all
    )

    has_many(:annotations, FileSetAnnotation,
      references: :id,
      foreign_key: :file_set_id,
      on_delete: :delete_all
    )

    belongs_to(:group_with_file_set, __MODULE__,
      foreign_key: :group_with,
      type: Ecto.UUID
    )
  end

  defp changeset_params do
    {[:accession_number, :role], [:work_id, :position, :poster_offset, :group_with]}
  end

  def changeset(file_set \\ %__MODULE__{}, params) do
    with {required_params, optional_params} <- changeset_params() do
      changeset =
        file_set
        |> preload_metadata()
        |> cast(rename_core_metadata(params), required_params ++ optional_params)
        |> validate_trimmed(:accession_number)
        |> prepare_assoc(:core_metadata)
        |> cast_assoc(:core_metadata)
        |> cast_assoc(:structural_metadata)
        |> cast_metadata_rows()
        |> validate_required([:core_metadata | required_params])
        |> validate_number(:poster_offset, greater_than_or_equal_to: 0)
        |> assoc_constraint(:work)
        |> assoc_constraint(:group_with_file_set)
        |> unsafe_validate_unique([:accession_number], Meadow.Repo)
        |> unique_constraint(:accession_number)

      changeset =
        case params do
          %{"rank" => _} -> changeset |> cast(params, [:rank])
          %{rank: _} -> changeset |> cast(params, [:rank])
          _ -> changeset |> set_rank(scope: [:work_id, :role])
        end

      changeset
      |> validate_group_with()
      |> foreign_key_constraint(:group_with)
    end
  end

  def update_changeset(file_set, params) do
    with {_, optional_params} <- changeset_params() do
      file_set
      |> preload_metadata()
      |> cast(rename_core_metadata(params), optional_params)
      |> prepare_assoc(:core_metadata)
      |> cast_assoc(:core_metadata)
      |> cast_assoc(:structural_metadata)
      |> cast_metadata_rows()
      |> set_rank(scope: [:work_id, :role])
      |> validate_number(:poster_offset, greater_than_or_equal_to: 0)
      |> validate_group_with()
      |> foreign_key_constraint(:group_with)
    end
  end

  # `derivatives` arrives as a `%{kind => location}` map and `extracted_metadata`
  # as a `%{tool => document}` map (the shapes the pipeline has always sent);
  # each becomes child rows, keeping the row ids of kinds/tools already present
  defp cast_metadata_rows(changeset) do
    changeset
    |> MultiValued.cast_entries(:derivatives,
      with: fn row, params, _position -> FileSetDerivative.changeset(row, params) end,
      key: &Map.get(&1, :kind),
      normalize: &identity/1,
      expand: &FileSetDerivative.to_params/1
    )
    |> MultiValued.cast_entries(:extracted_metadata,
      with: fn row, params, _position -> FileSetExtractedMetadata.changeset(row, params) end,
      key: &Map.get(&1, :tool),
      normalize: &identity/1,
      expand: &FileSetExtractedMetadata.to_params/1
    )
  end

  defp identity(value), do: value

  @doc "Nested preload list for the metadata rows of a file set"
  def metadata_preloads,
    do: [:core_metadata, :structural_metadata, :derivatives, extracted_metadata: :entries]

  @doc "Preload whatever metadata associations of a persisted file set are still missing"
  def preload_metadata(%__MODULE__{__meta__: %{state: :loaded}} = file_set) do
    missing =
      Enum.filter(metadata_preloads(), fn
        {assoc, _nested} -> not Ecto.assoc_loaded?(Map.get(file_set, assoc))
        assoc -> not Ecto.assoc_loaded?(Map.get(file_set, assoc))
      end)

    case missing do
      [] -> file_set
      preloads -> Meadow.Repo.preload(file_set, preloads)
    end
  end

  def preload_metadata(file_set), do: file_set

  def required_index_preloads,
    do:
      [work: [:collection] ++ Meadow.Data.Schemas.Work.metadata_preloads()] ++ metadata_preloads()

  defp rename_core_metadata(%{metadata: _, core_metadata: _} = params) do
    Logger.warning("Parameter map has both :metadata and :core_metadata. Ignoring :metadata.")
    params
  end

  defp rename_core_metadata(%{metadata: metadata} = params) do
    Logger.warning("Parameter map has :metadata. Renaming to :core_metadata.")
    params |> Map.put(:core_metadata, metadata) |> Map.delete(:metadata)
  end

  defp rename_core_metadata(params), do: params

  defp validate_group_with(changeset) do
    group_with_id = get_field(changeset, :group_with)

    if is_nil(group_with_id) do
      changeset
    else
      role = get_field(changeset, :role)

      if role && role.id == "A" do
        validate_group_with_target(changeset, group_with_id)
      else
        add_error(changeset, :group_with, "Only file sets with role 'Access (A)' can be grouped")
      end
    end
  end

  defp validate_group_with_target(changeset, group_with_id) do
    work_id = get_field(changeset, :work_id)

    case Meadow.Repo.get(__MODULE__, group_with_id) do
      %__MODULE__{group_with: nil, work_id: ^work_id, role: %{id: "A"}} ->
        changeset

      %__MODULE__{group_with: nil, work_id: ^work_id} ->
        add_error(changeset, :group_with, "Target file set must have role 'Access (A)'")

      %__MODULE__{group_with: nil} ->
        add_error(changeset, :group_with, "Target file set belongs to a different work")

      %__MODULE__{} ->
        add_error(changeset, :group_with, "Target file set already has a group_with value")

      nil ->
        add_error(changeset, :group_with, "Target file set not found")
    end
  end
end
