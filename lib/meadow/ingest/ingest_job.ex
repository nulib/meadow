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
    field :presigned_url, :string

    belongs_to :project, Meadow.Ingest.Project

    timestamps()
  end

  @doc false
  def changeset(ingest_job, attrs) do
    ingest_job
    |> cast(attrs, [:name, :presigned_url, :project_id])
    |> validate_required([:name, :presigned_url, :project_id])
    |> unique_constraint(:name)
  end
end
