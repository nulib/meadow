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
    field :status, :string, default: "pending"
    field :error, :string

    timestamps()
  end

  def changeset(donut_work, params \\ %{}) do
    donut_work
    |> cast(params, [
      :work_id,
      :status,
      :error
    ])
  end
end
