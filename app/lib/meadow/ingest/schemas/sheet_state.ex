defmodule Meadow.Ingest.Schemas.SheetState do
  @moduledoc """
  The validation state of one stage (`file`, `rows`, `overall`) of an ingest
  sheet (`ingest_sheet_states`).
  """

  use Ecto.Schema
  import Ecto.Changeset

  @names ~w(file rows overall)

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "ingest_sheet_states" do
    belongs_to :sheet, Meadow.Ingest.Schemas.Sheet
    field :name, :string
    field :state, :string
  end

  def names, do: @names

  def changeset(sheet_state, params, _position \\ nil) do
    sheet_state
    |> cast(params, [:name, :state])
    |> validate_required([:name, :state])
    |> validate_inclusion(:name, @names)
  end
end
