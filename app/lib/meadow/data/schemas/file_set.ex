defmodule Meadow.Data.Schemas.FileSet do
  @moduledoc """
  FileSets are used to describe objects stored in Amazon S3
  """
  use Ecto.Schema
  alias Meadow.Data.Schemas.{ActionState, FileSetCoreMetadata, FileSetStructuralMetadata, Work}
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
    field(:dominant_color, :map)

    embeds_one(:core_metadata, FileSetCoreMetadata, on_replace: :update)
    embeds_one(:structural_metadata, FileSetStructuralMetadata, on_replace: :delete)
    timestamps()

    belongs_to(:work, Work)

    has_many(:action_states, ActionState,
      references: :id,
      foreign_key: :object_id,
      on_delete: :delete_all
    )
  end

  defp changeset_params do
    {[:accession_number, :role],
     [:work_id, :position, :extracted_metadata, :derivatives, :poster_offset, :dominant_color]}
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
      |> unsafe_validate_unique([:accession_number], Meadow.Repo)
      |> unique_constraint(:accession_number)
      |> set_rank(scope: [:work_id, :role])
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
    end
  end

  defp rename_core_metadata(%{metadata: _, core_metadata: _} = params) do
    Logger.warn("Parameter map has both :metadata and :core_metadata. Ignoring :metadata.")
    params
  end

  defp rename_core_metadata(%{metadata: metadata} = params) do
    Logger.warn("Parameter map has :metadata. Renaming to :core_metadata.")
    params |> Map.put(:core_metadata, metadata) |> Map.delete(:metadata)
  end

  defp rename_core_metadata(params), do: params
end
