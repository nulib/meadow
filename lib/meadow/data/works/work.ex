defmodule Meadow.Data.Works.Work do
  @moduledoc """
  A repository data object. Embeds one Metadata map and many FileSets.
  """

  use Ecto.Schema
  alias Meadow.Data.FileSets.FileSet
  alias Meadow.Data.Works.WorkMetadata

  import Ecto.Changeset

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  @foreign_key_type Ecto.ULID
  schema "works" do
    field :accession_number, :string
    field :visibility, :string
    field :work_type, :string
    timestamps()

    embeds_one :metadata, WorkMetadata, on_replace: :update

    has_many :file_sets, FileSet
  end

  def changeset(work, attrs) do
    work
    |> cast(attrs, [:accession_number, :visibility, :work_type])
    |> cast_embed(:metadata)
    |> cast_assoc(:file_sets)
    |> validate_required([:accession_number, :metadata, :visibility, :work_type])
    |> unique_constraint(:accession_number)
  end
end
