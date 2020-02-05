defmodule Meadow.Data.Schemas.IndexTime do
  @moduledoc """
  IndexTimes are use to track the last time an item was indexed
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: false}
  schema "index_times" do
    field :indexed_at, :utc_datetime_usec
  end

  def changeset(index_time, params) do
    index_time
    |> cast(params, [:id, :indexed_at])
    |> validate_required([:id, :indexed_at])
  end
end
