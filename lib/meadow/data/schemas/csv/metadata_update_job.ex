defmodule Meadow.Data.Schemas.CSV.MetadataUpdateJob do
  @moduledoc """
  Schema for metadata update job
  """
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "csv_metadata_update_jobs" do
    field(:source, :string)
    field(:rows, :integer)
    field(:errors, {:array, :map}, default: [])
    field(:status, :string)
    field(:started_at, :utc_datetime_usec)
    field(:user, :string)
    timestamps()
  end

  def changeset(job, attrs) do
    job
    |> cast(attrs, [:source, :rows, :errors, :status, :user, :started_at])
    |> validate_required([:source, :status])
  end
end
