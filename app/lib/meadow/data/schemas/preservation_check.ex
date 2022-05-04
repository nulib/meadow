defmodule Meadow.Data.Schemas.PreservationCheck do
  @moduledoc """
  Schema for preservation checks
  """
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  @status ~w(active complete error timeout)

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "preservation_checks" do
    field(:filename, :string)
    field(:location, :string)
    field(:status, :string)
    field :invalid_rows, :integer, default: 0
    field :active, :boolean, default: false
    timestamps()
  end

  def changeset(job, attrs) do
    job
    |> cast(attrs, [:active, :filename, :location, :status, :invalid_rows])
    |> validate_inclusion(:status, @status)
    |> unique_constraint(:active)
  end
end
