defmodule Meadow.Data.Schemas.WorkAdministrativeMetadata do
  @moduledoc """
  Administrative metadata embedded in Work records.
  """

  import Ecto.Changeset
  use Ecto.Schema

  @timestamps_opts [type: :utc_datetime_usec]
  embedded_schema do
    timestamps()
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, [])
  end
end
