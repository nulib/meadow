defmodule Meadow.Repo.Migrations.AddUlidIdToIngestSheetRows do
  use Ecto.Migration
  import Ecto.Query

  def up do
    drop constraint(:ingest_sheet_rows, "ingest_sheet_rows_pkey")

    alter table(:ingest_sheet_rows) do
      modify :ingest_sheet_id, :binary_id, null: false, primary_key: false
      modify :row, :integer, null: false, primary_key: false
      add :id, :binary_id
    end

    flush()

    from(r in "ingest_sheet_rows",
      update: [
        set: [id: fragment("uuid_in(md5(random()::text || clock_timestamp()::text)::cstring)")]
      ]
    )
    |> Meadow.Repo.update_all([])

    alter table(:ingest_sheet_rows) do
      modify(:id, :binary_id, primary_key: true)
    end
  end

  def down do
    alter table(:ingest_sheet_rows) do
      modify :ingest_sheet_id, :binary_id, null: false, primary_key: true
      modify :row, :integer, null: false, primary_key: true
      remove :id
    end
  end
end
