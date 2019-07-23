defmodule Meadow.Ingest.IngestJob do
  @moduledoc """
  IngestJob represents an inventory sheet upload
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.ULID, autogenerate: true}
  @foreign_key_type Ecto.ULID
  schema "ingest_jobs" do
    field :name, :string
    field :filename, :string

    belongs_to :project, Meadow.Ingest.Project

    timestamps()
  end

  @doc false
  def changeset(ingest_job, attrs) do
    ingest_job
    |> cast(attrs, [:name, :filename, :project_id])
    |> validate_required([:name, :filename, :project_id])
    |> validate_csv_format()
    |> unique_constraint(:name)
  end

  def validate_csv_format(changeset) do
    name = get_field(changeset, :filename)

    if name && Path.extname(name) == ".csv" do
      changeset
    else
      add_error(changeset, :filename, "is not a csv")
    end
  end
end
