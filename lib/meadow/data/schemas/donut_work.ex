defmodule Meadow.Data.Schemas.DonutWork do
  @moduledoc """
  Information about works to migrate from Donut
  """
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  @timestamps_opts [type: :utc_datetime_usec]
  schema "donut_works" do
    field :work_id, Ecto.UUID, primary_key: true
    field :manifest, :string
    field :last_modified, :utc_datetime
    field :status, :string, default: "pending"
    field :error, :string

    timestamps()
  end

  def changeset(donut_work, params \\ %{}) do
    donut_work
    |> cast(params, [
      :work_id,
      :manifest,
      :last_modified,
      :status,
      :error
    ])
    |> validate_required([:work_id, :manifest, :last_modified])
  end
end
