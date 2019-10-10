defmodule Meadow.Repo.Migrations.PromoteIngestSheetRowAccessionNumber do
  use Ecto.Migration

  def up do
    alter table(:ingest_sheet_rows) do
      add(:file_set_accession_number, :string)
    end

    flush()

    execute """
      UPDATE ingest_sheet_rows
      SET file_set_accession_number = (
        SELECT obj->>'value'
        FROM ingest_sheet_rows isr, jsonb_array_elements(isr.fields) obj
        WHERE obj->>'header' = 'accession_number'
        AND isr.ingest_sheet_id = ingest_sheet_rows.ingest_sheet_id
        AND isr.row = ingest_sheet_rows.row
      );
    """
  end

  def down do
    alter table(:ingest_sheet_rows) do
      remove(:file_set_accession_number)
    end
  end
end
