defmodule Meadow.Data.Schemas.FileSetAnnotation do
  @moduledoc """
  Schema for file set annotations (e.g., transcriptions)
  """
  use Ecto.Schema
  alias Meadow.Data.Schemas.FileSet

  import Ecto.Changeset

  @status ~w(pending in_progress completed error)

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "file_set_annotations" do
    field(:type, :string)
    field(:language, {:array, :string})
    field(:model, :string)
    field(:s3_location, :string)
    field(:status, :string)

    belongs_to(:file_set, FileSet)

    timestamps()
  end

  def changeset(annotation \\ %__MODULE__{}, attrs) do
    annotation
    |> cast(attrs, [:file_set_id, :type, :language, :model, :s3_location, :status])
    |> validate_required([:file_set_id, :type, :status])
    |> validate_inclusion(:status, @status)
    |> assoc_constraint(:file_set)
    |> unique_constraint([:file_set_id, :type],
      name: :file_set_annotations_file_set_id_type_index,
      message: "annotation of this type already exists for this file set"
    )
  end
end
