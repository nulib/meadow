defmodule Meadow.Ingest.Schemas.Row do
  @moduledoc """
  Row represents a single row of an ingest sheet
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "ingest_sheet_rows" do
    belongs_to :sheet, Meadow.Ingest.Schemas.Sheet
    field :row, :integer
    field :state, :string, default: "pending"
    field :file_set_accession_number, :string

    embeds_many :errors, Error, primary_key: false, on_replace: :delete do
      field :field, :string
      field :message, :string
    end

    embeds_many :fields, Field, primary_key: false, on_replace: :delete do
      field :header, :string
      field :value, :string
    end

    field :single_field_pair, :string, virtual: true
    timestamps()
  end

  def field_value(row, field_name) when is_binary(field_name) do
    case row.fields
         |> Enum.find(fn field -> field.header == field_name end) do
      nil -> nil
      field -> field.value
    end
  end

  def field_value(row, field_name), do: field_value(row, to_string(field_name))

  @doc false
  def changeset(row, attrs) do
    row
    |> cast(attrs, [:file_set_accession_number, :state])
    |> cast_embed(:errors, with: &error_changeset/2)
    |> cast_embed(:fields, with: &field_changeset/2)
    |> validate_required([:sheet_id, :row, :file_set_accession_number])
    |> assoc_constraint(:sheet)
  end

  def error_changeset(row, attrs) do
    row
    |> cast(attrs, [:field, :message])
  end

  def field_changeset(row, attrs) do
    row
    |> cast(attrs, [:header, :value])
  end

  def state_changeset(row, attrs) do
    row
    |> cast(attrs, [:state])
    |> cast_embed(:errors, with: &error_changeset/2)
    |> validate_required([:sheet_id, :row])
    |> assoc_constraint(:sheet)
    |> validate_required([:state])
  end

  def data_changeset(row, _attrs) do
    row
    |> cast_embed(:errors, with: &error_changeset/2)
    |> cast_embed(:fields, with: &field_changeset/2)
    |> validate_required([:sheet_id, :row])
  end
end
