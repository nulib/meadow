defmodule Meadow.Ingest.Schemas.Row do
  @moduledoc """
  Row represents a single row of an ingest sheet. Its header/value pairs and
  validation errors are child rows (`ingest_sheet_row_fields`,
  `ingest_sheet_row_errors`).
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Meadow.Data.Schemas.MultiValued
  alias Meadow.Ingest.Schemas.{RowError, RowField}

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "ingest_sheet_rows" do
    belongs_to :sheet, Meadow.Ingest.Schemas.Sheet
    field :row, :integer
    field :state, :string, default: "pending"
    field :file_set_accession_number, :string

    has_many :errors, RowError,
      foreign_key: :row_id,
      preload_order: [asc: :position],
      on_replace: :delete

    has_many :fields, RowField,
      foreign_key: :row_id,
      preload_order: [asc: :position],
      on_replace: :delete

    timestamps()
  end

  def field_value(row, field_name) when is_binary(field_name) do
    row
    |> preload_children()
    |> Map.get(:fields)
    |> Enum.find(fn field -> field.header == field_name end)
    |> case do
      nil -> nil
      field -> field.value
    end
  end

  def field_value(row, field_name), do: field_value(row, to_string(field_name))

  @doc "Preloads for a row's child rows"
  def preloads, do: [:fields, :errors]

  @doc false
  def changeset(row, attrs) do
    row
    |> preload_children()
    |> cast(attrs, [:file_set_accession_number, :state])
    |> cast_children([:errors, :fields])
    |> validate_required([:sheet_id, :row, :file_set_accession_number])
    |> assoc_constraint(:sheet)
  end

  def state_changeset(row, attrs) do
    row
    |> preload_children()
    |> cast(attrs, [:state])
    |> cast_children([:errors])
    |> validate_required([:sheet_id, :row])
    |> assoc_constraint(:sheet)
    |> validate_required([:state])
  end

  def data_changeset(row, _attrs) do
    row
    |> preload_children()
    |> cast(%{}, [])
    |> cast_children([:errors, :fields])
    |> validate_required([:sheet_id, :row])
  end

  defp cast_children(changeset, assocs) do
    Enum.reduce(assocs, changeset, fn
      :errors, acc ->
        MultiValued.cast_entries(acc, :errors,
          with: &RowError.changeset/3,
          key: &Map.get(&1, :message)
        )

      :fields, acc ->
        MultiValued.cast_entries(acc, :fields,
          with: &RowField.changeset/3,
          key: &Map.get(&1, :header)
        )
    end)
  end

  @doc "Preload the field/error rows of a persisted row if they are not loaded yet"
  def preload_children(%__MODULE__{__meta__: %{state: :loaded}} = row) do
    missing = Enum.reject(preloads(), &Ecto.assoc_loaded?(Map.get(row, &1)))
    if missing == [], do: row, else: Meadow.Repo.preload(row, missing)
  end

  def preload_children(row), do: row
end
