defmodule Meadow.Ingest.IngestSheets.IngestSheetRow do
  @moduledoc """
  IngestSheetRow represents a single row of an ingest sheet
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @foreign_key_type Ecto.ULID

  schema "ingest_sheet_rows" do
    belongs_to :ingest_sheet, Meadow.Ingest.IngestSheets.IngestSheet, primary_key: true
    field :row, :integer, primary_key: true
    field :state, :string, default: "pending"

    embeds_many :errors, Error, primary_key: false, on_replace: :delete do
      field :field, :string
      field :message, :string
    end

    embeds_many :fields, Field, primary_key: false, on_replace: :delete do
      field :header, :string
      field :value, :string
    end

    timestamps()
  end

  @doc false
  def changeset(ingest_sheet_row, attrs) do
    ingest_sheet_row
    |> cast(attrs, [:state])
    |> cast_embed(:errors, with: &error_changeset/2)
    |> cast_embed(:fields, with: &field_changeset/2)
    |> validate_required([:ingest_sheet_id, :row])
    |> assoc_constraint(:ingest_sheet)
  end

  def error_changeset(ingest_sheet_row, attrs) do
    ingest_sheet_row
    |> cast(attrs, [:field, :message])
  end

  def field_changeset(ingest_sheet_row, attrs) do
    ingest_sheet_row
    |> cast(attrs, [:header, :value])
  end

  def field_value(row, field_name) when is_binary(field_name) do
    case row.fields
         |> Enum.find(fn field -> field.header == field_name end) do
      nil -> nil
      field -> field.value
    end
  end

  def field_value(row, field_name), do: field_value(row, to_string(field_name))

  def state_changeset(ingest_sheet_row, attrs) do
    ingest_sheet_row
    |> cast(attrs, [:state])
    |> validate_required([:ingest_sheet_id, :row])
    |> assoc_constraint(:ingest_sheet)
    |> validate_required([:state])
  end

  def data_changeset(ingest_sheet_row, _attrs) do
    ingest_sheet_row
    |> cast_embed(:errors, with: &error_changeset/2)
    |> cast_embed(:fields, with: &field_changeset/2)
    |> validate_required([:ingest_sheet_id, :row])
  end
end
