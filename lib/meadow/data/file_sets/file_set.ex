defmodule Meadow.Data.FileSets.FileSet do
  @moduledoc """
  FileSets are used to describe objects stored in Amazon S3
  """
  use Ecto.Schema
  alias Meadow.Data.FileSets.FileSetMetadata
  alias Meadow.Data.Works.Work

  import Ecto.Changeset

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  @foreign_key_type Ecto.ULID
  schema "file_sets" do
    field :accession_number
    embeds_one :metadata, FileSetMetadata
    timestamps()

    belongs_to :work, Work
  end

  def changeset(file_set, params) do
    file_set
    |> cast(params, [:accession_number])
    |> cast_embed(:metadata)
    |> validate_required([:accession_number])
    |> unique_constraint(:accession_number)
  end
end
