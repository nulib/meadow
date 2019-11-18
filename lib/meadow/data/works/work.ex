defmodule Meadow.Data.Works.Work do
  @moduledoc """
  A repository data object. Embeds one Metadata map and many FileSets.
  """

  use Ecto.Schema
  alias Meadow.Data.AuditEntries.AuditEntry
  alias Meadow.Data.Collections.Collection
  alias Meadow.Data.FileSets.FileSet
  alias Meadow.Data.Works.WorkMetadata

  import Ecto.Changeset

  use Meadow.Constants

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  @foreign_key_type Ecto.ULID
  schema "works" do
    field :accession_number, :string
    field :visibility, :string
    field :work_type, :string
    timestamps()

    embeds_one :metadata, WorkMetadata, on_replace: :update

    has_many :file_sets, FileSet

    has_many :audit_entries, AuditEntry,
      references: :id,
      foreign_key: :object_id,
      on_delete: :delete_all

    many_to_many(:collections, Collection, join_through: "collections_works", on_replace: :delete)
  end

  def changeset(work, attrs) do
    required_params = [:accession_number, :visibility, :work_type]
    optional_params = []

    work
    |> cast(attrs, required_params ++ optional_params)
    |> cast_embed(:metadata)
    |> cast_assoc(:file_sets)
    |> validate_required(required_params)
    |> validate_inclusion(:visibility, @visibility)
    |> validate_inclusion(:work_type, @work_types)
    |> unique_constraint(:accession_number)
  end
end
