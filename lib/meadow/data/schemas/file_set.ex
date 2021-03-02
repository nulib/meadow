defmodule Meadow.Data.Schemas.FileSet do
  @moduledoc """
  FileSets are used to describe objects stored in Amazon S3
  """
  use Ecto.Schema
  alias Meadow.Data.Schemas.ActionState
  alias Meadow.Data.Schemas.FileSetMetadata
  alias Meadow.Data.Schemas.Work
  alias Meadow.Data.Types
  alias Meadow.Utils.Exif, as: ExifUtil

  import Ecto.Changeset
  import EctoRanked
  import Meadow.Data.Schemas.Validations

  use Meadow.Constants

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "file_sets" do
    field :accession_number
    field :role, Types.CodedTerm
    field :rank, :integer
    field :position, :any, virtual: true

    embeds_one :metadata, FileSetMetadata, on_replace: :update
    timestamps()

    belongs_to :work, Work

    has_many :action_states, ActionState,
      references: :id,
      foreign_key: :object_id,
      on_delete: :delete_all
  end

  defp changeset_params do
    {[:accession_number, :role], [:work_id, :position]}
  end

  def changeset(file_set \\ %__MODULE__{}, params) do
    with {required_params, optional_params} <- changeset_params() do
      file_set
      |> cast(params, required_params ++ optional_params)
      |> prepare_embed(:metadata)
      |> cast_embed(:metadata)
      |> validate_required([:metadata | required_params])
      |> assoc_constraint(:work)
      |> unsafe_validate_unique([:accession_number], Meadow.Repo)
      |> unique_constraint(:accession_number)
      |> set_rank(scope: [:work_id, :role])
    end
  end

  def migration_changeset(file_set, %{role: "am"} = params) do
    params = put_in(params.role, %{id: "A", scheme: "FILE_SET_ROLE"})
    migration_changeset(file_set, params)
  end

  def migration_changeset(file_set, params) do
    with {required_params, optional_params} <- changeset_params() do
      required_params = [:id | required_params]

      file_set
      |> cast(params, required_params ++ optional_params)
      |> prepare_embed(:metadata)
      |> cast_embed(:metadata)
      |> validate_required([:metadata | required_params])
      |> assoc_constraint(:work)
      |> unsafe_validate_unique([:accession_number], Meadow.Repo)
      |> unique_constraint(:accession_number)
      |> set_rank(scope: [:work_id, :role])
    end
  end

  def update_changeset(file_set, params) do
    file_set
    |> cast(params, [:work_id, :position])
    |> prepare_embed(:metadata)
    |> cast_embed(:metadata)
    |> set_rank(scope: [:work_id, :role])
  end

  defimpl Elasticsearch.Document, for: Meadow.Data.Schemas.FileSet do
    def id(file_set), do: file_set.id
    def routing(_), do: false

    def encode(file_set) do
      %{
        createDate: file_set.inserted_at,
        description: file_set.metadata.description,
        label: file_set.metadata.label,
        mime_type: file_set.metadata.mime_type,
        model: %{application: "Meadow", name: "FileSet"},
        modifiedDate: file_set.updated_at,
        role: format(file_set.role),
        visibility: format(file_set.work.visibility),
        workId: file_set.work.id,
        exif: ExifUtil.index(file_set.metadata.exif)
      }
    end

    defp format(%{id: id, name: name}), do: %{id: id, name: name}
    defp format(%{id: id, title: title}), do: %{id: id, title: title}
    defp format(%{id: _id, label: _label, scheme: _scheme} = field), do: field
    defp format(_), do: %{}
  end
end
