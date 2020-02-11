defmodule Meadow.Ingest.Schemas.SheetWorks do
  @moduledoc """
  Links ingest sheets to works
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type Ecto.UUID
  schema "ingest_sheet_works" do
    belongs_to(:sheet, Meadow.Ingest.Schemas.Sheet, primary_key: true)
    belongs_to(:work, Meadow.Data.Schemas.Work, primary_key: true)
  end

  @doc false
  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:sheet, :work])
    |> validate_required([:sheet, :work])
  end
end
