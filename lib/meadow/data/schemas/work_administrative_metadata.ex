defmodule Meadow.Data.Schemas.WorkAdministrativeMetadata do
  @moduledoc """
  Administrative metadata embedded in Work records.
  """

  import Ecto.Changeset
  use Ecto.Schema

  @timestamps_opts [type: :utc_datetime_usec]
  embedded_schema do
    field :preservation_level, :integer
    field :rights_statement, :string

    timestamps()
  end

  def changeset(metadata, params) do
    metadata
    |> cast(params, [
      :preservation_level,
      :rights_statement
    ])
  end
end
