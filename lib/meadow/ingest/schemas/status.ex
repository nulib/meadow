defmodule Meadow.Ingest.Schemas.Status do
  @moduledoc """
  Status represents the ingest status of a single ingest sheet or ingest sheet row
  """

  use Ecto.Schema
  use Meadow.Constants

  import Ecto.Changeset

  @primary_key false
  @foreign_key_type Ecto.UUID
  @sheet_row -1

  schema "ingest_sheet_status" do
    field :sheet_id, :string, primary_key: true
    field :row, :integer, default: @sheet_row, primary_key: true
    field :status, :string, default: "initialized"
  end

  @doc false
  def changeset(ingest_sheet_row, attrs) do
    ingest_sheet_row
    |> cast(attrs, [:status])
    |> validate_required([:sheet_id, :row, :status])
    |> validate_change(:status, &validate_ingest_status/2)
  end

  def validate_ingest_status(_, _value) do
    # is_nil(value) || value in @ingest_statuses
    []
  end
end
