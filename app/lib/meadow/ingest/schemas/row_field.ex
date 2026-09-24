defmodule Meadow.Ingest.Schemas.RowField do
  @moduledoc """
  One header/value pair of an ingest sheet row (`ingest_sheet_row_fields`),
  in the sheet's column order.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "ingest_sheet_row_fields" do
    belongs_to :row, Meadow.Ingest.Schemas.Row
    field :position, :integer
    field :header, :string
    field :value, :string
  end

  def changeset(field, params, position \\ nil) do
    field
    |> cast(params, [:header, :value])
    |> put_position(position)
    |> validate_required([:header])
  end

  defp put_position(changeset, nil), do: changeset
  defp put_position(changeset, position), do: put_change(changeset, :position, position)
end
