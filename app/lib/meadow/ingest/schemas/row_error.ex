defmodule Meadow.Ingest.Schemas.RowError do
  @moduledoc """
  One validation error on an ingest sheet row (`ingest_sheet_row_errors`).
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "ingest_sheet_row_errors" do
    belongs_to :row, Meadow.Ingest.Schemas.Row
    field :position, :integer
    field :field, :string
    field :message, :string
  end

  def changeset(error, params, position \\ nil) do
    error
    |> cast(params, [:field, :message])
    |> put_position(position)
  end

  defp put_position(changeset, nil), do: changeset
  defp put_position(changeset, position), do: put_change(changeset, :position, position)
end
