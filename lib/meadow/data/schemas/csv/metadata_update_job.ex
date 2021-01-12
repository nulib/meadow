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
    field(:filename, :string)
    field(:source, :string)
    field(:rows, :integer)
    field(:errors, {:array, :map}, default: [])
    field(:active, :boolean)
    field(:status, :string)
    field(:started_at, :utc_datetime_usec)
    field(:user, :string)
    timestamps()
  end

  def changeset(job, attrs) do
    with attrs <- set_active(attrs) do
      job
      |> cast(attrs, [:filename, :source, :rows, :errors, :active, :status, :user, :started_at])
      |> validate_required([:source, :status])
    end
  end

  defp set_active(attrs) do
    case Map.get(attrs, :status, nil) do
      nil -> attrs
      "processing" -> Map.put(attrs, :active, true)
      "validating" -> Map.put(attrs, :active, true)
      _ -> Map.put(attrs, :active, false)
    end
  end
end
