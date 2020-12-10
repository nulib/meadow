defmodule Meadow.Data.Schemas.FileSet do
  @moduledoc """
  FileSets are used to describe objects stored in Amazon S3
  """
  use Ecto.Schema
  alias Meadow.Data.Schemas.ActionState
  alias Meadow.Data.Schemas.FileSetMetadata
  alias Meadow.Data.Schemas.Work

  import Ecto.Changeset
  import EctoRanked
  import Meadow.Data.Schemas.Validations

  use Meadow.Constants

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "file_sets" do
    field :accession_number
    field :role, :string
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

  def changeset(file_set, params) do
    file_set
    |> cast(params, [:accession_number, :work_id, :role, :rank, :position])
    |> prepare_embed(:metadata)
    |> cast_embed(:metadata)
    |> validate_required([:accession_number, :role, :metadata])
    |> assoc_constraint(:work)
    |> unsafe_validate_unique([:accession_number], Meadow.Repo)
    |> unique_constraint(:accession_number)
    |> validate_inclusion(:role, @file_set_roles)
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
        model: %{application: "Meadow", name: "FileSet"},
        modifiedDate: file_set.updated_at,
        visibility: format(file_set.work.visibility),
        workId: file_set.work.id
      }
    end

    defp format(%{id: id, name: name}), do: %{id: id, name: name}
    defp format(%{id: id, title: title}), do: %{id: id, title: title}
    defp format(%{id: _id, label: _label, scheme: _scheme} = field), do: field
    defp format(_), do: %{}
  end
end
