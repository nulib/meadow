defmodule Meadow.Data.Schemas.CSV.MetadataUpdateJob do
  @moduledoc """
  Schema for metadata update job
  """
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  @active_states ~w(processing validating)

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
    field(:retries, :integer, default: 0)
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
    with status <- Map.get(attrs, :status, nil) do
      cond do
        is_nil(status) -> attrs
        Enum.member?(@active_states, status) -> Map.put(attrs, :active, true)
        true -> Map.put(attrs, :active, false)
      end
    end
  end
end
