defmodule Meadow.Data.FileSets.FileSet do
  @moduledoc """
  FileSets are used to describe objects stored in Amazon S3
  """
  use Ecto.Schema
  alias Meadow.Data.AuditEntries.AuditEntry
  alias Meadow.Data.FileSets.FileSetMetadata
  alias Meadow.Data.Works.Work

  import Ecto.Changeset

  use Meadow.Constants

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  @foreign_key_type Ecto.ULID
  schema "file_sets" do
    field :accession_number
    field :role, :string
    embeds_one :metadata, FileSetMetadata, on_replace: :update
    timestamps()

    belongs_to :work, Work

    has_many :audit_entries, AuditEntry,
      references: :id,
      foreign_key: :object_id,
      on_delete: :delete_all
  end

  def changeset(file_set, params) do
    file_set
    |> cast(params, [:accession_number, :work_id, :role])
    |> cast_embed(:metadata)
    |> validate_required([:accession_number, :role, :metadata])
    |> assoc_constraint(:work)
    |> unsafe_validate_unique([:accession_number], Meadow.Repo)
    |> unique_constraint(:accession_number)
    |> validate_inclusion(:role, @file_set_roles)
  end
end
