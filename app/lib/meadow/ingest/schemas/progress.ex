defmodule Meadow.Ingest.Schemas.Progress do
  @moduledoc """
  This modeule defines the Ecto.Schema
  and Ecto.Changeset for Meadow.Ingest.Schemas.Progress

  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "ingest_progress" do
    belongs_to :row, Meadow.Ingest.Schemas.Row, primary_key: true
    field :action, :string, primary_key: true
    field :status, :string
    timestamps()
  end

  def changeset(record, attrs \\ %{}) do
    record
    |> cast(attrs, [:row_id, :action, :status, :updated_at])
    |> validate_required([:row_id, :action, :status])
  end
end
