defmodule Meadow.Data.Schemas.FileSet do
  @moduledoc """
  FileSets are used to describe objects stored in Amazon S3
  """
  use Ecto.Schema
  alias Meadow.Data.Schemas.{ActionState, FileSetAnnotation, FileSetCoreMetadata, FileSetStructuralMetadata, Work}
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
    field(:extracted_metadata, :map)
    field(:role, Types.CodedTerm)
    field(:rank, :integer)
    field(:position, :any, virtual: true)
    field(:derivatives, :map)
    field(:poster_offset, :integer)

    embeds_one(:core_metadata, FileSetCoreMetadata, on_replace: :update)
    embeds_one(:structural_metadata, FileSetStructuralMetadata, on_replace: :delete)
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
    {[:accession_number, :role],
     [:work_id, :position, :extracted_metadata, :derivatives, :poster_offset, :group_with]}
  end

  def changeset(file_set \\ %__MODULE__{}, params) do
    with {required_params, optional_params} <- changeset_params() do
      file_set
      |> cast(rename_core_metadata(params), required_params ++ optional_params)
      |> prepare_embed(:core_metadata)
      |> cast_embed(:core_metadata)
      |> prepare_embed(:structural_metadata)
      |> cast_embed(:structural_metadata)
      |> validate_required([:core_metadata | required_params])
      |> validate_number(:poster_offset, greater_than_or_equal_to: 0)
      |> assoc_constraint(:work)
      |> assoc_constraint(:group_with_file_set)
      |> unsafe_validate_unique([:accession_number], Meadow.Repo)
      |> unique_constraint(:accession_number)
      |> set_rank(scope: [:work_id, :role])
      |> validate_group_with()
      |> foreign_key_constraint(:group_with)
    end
  end

  def update_changeset(file_set, params) do
    with {_, optional_params} <- changeset_params() do
      file_set
      |> cast(rename_core_metadata(params), optional_params)
      |> prepare_embed(:core_metadata)
      |> cast_embed(:core_metadata)
      |> prepare_embed(:structural_metadata)
      |> cast_embed(:structural_metadata)
      |> set_rank(scope: [:work_id, :role])
      |> validate_number(:poster_offset, greater_than_or_equal_to: 0)
      |> validate_group_with()
      |> foreign_key_constraint(:group_with)
    end
  end

  def required_index_preloads, do: [:work]

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
