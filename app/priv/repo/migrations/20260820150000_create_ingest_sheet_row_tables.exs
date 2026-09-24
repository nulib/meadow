defmodule Meadow.Repo.Migrations.CreateIngestSheetRowTables do
  @moduledoc """
  Move ingest sheet row fields and errors, and ingest sheet stage states, out
  of jsonb into tables: `ingest_sheet_row_fields`, `ingest_sheet_row_errors`
  and `ingest_sheet_states`. Existing data is backfilled; the jsonb columns
  stay until the cleanup migration. `down/0` drops the new tables.
  """

  use Ecto.Migration

  require Logger

  def up do
    create table(:ingest_sheet_row_fields, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(:row_id, references(:ingest_sheet_rows, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:position, :integer, null: false)
      add(:header, :text, null: false)
      add(:value, :text)
    end

    create(index(:ingest_sheet_row_fields, [:row_id, :position]))
    create(index(:ingest_sheet_row_fields, [:header, :value]))

    create table(:ingest_sheet_row_errors, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      add(:row_id, references(:ingest_sheet_rows, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:position, :integer, null: false)
      add(:field, :text)
      add(:message, :text)
    end

    create(index(:ingest_sheet_row_errors, [:row_id]))

    create table(:ingest_sheet_states, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))
      add(:sheet_id, references(:ingest_sheets, type: :uuid, on_delete: :delete_all), null: false)
      add(:name, :text, null: false)
      add(:state, :text, null: false)
    end

    create(
      constraint(:ingest_sheet_states, :name_must_be_known,
        check: "name IN ('file', 'rows', 'overall')"
      )
    )

    create(unique_index(:ingest_sheet_states, [:sheet_id, :name]))

    flush()

    Logger.info("Backfilling ingest_sheet_row_fields")

    execute("""
    INSERT INTO ingest_sheet_row_fields (row_id, position, header, value)
    SELECT r.id, e.ordinality - 1, e.elem->>'header', e.elem->>'value'
    FROM ingest_sheet_rows r
    CROSS JOIN LATERAL jsonb_array_elements(CASE WHEN jsonb_typeof(r.fields) = 'array' THEN r.fields ELSE '[]'::jsonb END)
      WITH ORDINALITY e(elem, ordinality)
    WHERE e.elem->>'header' IS NOT NULL
    """)

    Logger.info("Backfilling ingest_sheet_row_errors")

    execute("""
    INSERT INTO ingest_sheet_row_errors (row_id, position, field, message)
    SELECT r.id, e.ordinality - 1, e.elem->>'field', e.elem->>'message'
    FROM ingest_sheet_rows r
    CROSS JOIN LATERAL jsonb_array_elements(CASE WHEN jsonb_typeof(r.errors) = 'array' THEN r.errors ELSE '[]'::jsonb END)
      WITH ORDINALITY e(elem, ordinality)
    """)

    Logger.info("Backfilling ingest_sheet_states")

    execute("""
    INSERT INTO ingest_sheet_states (sheet_id, name, state)
    SELECT DISTINCT ON (s.id, e.elem->>'name') s.id, e.elem->>'name', e.elem->>'state'
    FROM ingest_sheets s
    CROSS JOIN LATERAL jsonb_array_elements(CASE WHEN jsonb_typeof(s.state) = 'array' THEN s.state ELSE '[]'::jsonb END) e(elem)
    WHERE e.elem->>'name' IN ('file', 'rows', 'overall') AND e.elem->>'state' IS NOT NULL
    """)

    flush()

    Logger.info(
      "Backfilled #{count!("SELECT count(*) FROM ingest_sheet_row_fields")} row fields, " <>
        "#{count!("SELECT count(*) FROM ingest_sheet_row_errors")} row errors, " <>
        "#{count!("SELECT count(*) FROM ingest_sheet_states")} sheet states"
    )
  end

  def down do
    drop(table(:ingest_sheet_states))
    drop(table(:ingest_sheet_row_errors))
    drop(table(:ingest_sheet_row_fields))
  end

  defp count!(sql) do
    %{rows: [[count]]} = repo().query!(sql)
    count || 0
  end
end
