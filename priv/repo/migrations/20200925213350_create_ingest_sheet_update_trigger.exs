defmodule Meadow.Repo.Migrations.CreateIngestSheetUpdateTrigger do
  use Ecto.Migration

  def up do
    execute """
    CREATE OR REPLACE FUNCTION update_sheet_status_when_progress_changes()
      RETURNS trigger AS $$
    DECLARE
      current_sheet_id ingest_sheets.id%TYPE;
      lock_id bigint;
      pending integer;
    BEGIN
      SELECT ingest_sheet_rows.sheet_id INTO current_sheet_id
      FROM ingest_sheet_rows WHERE ingest_sheet_rows.id = NEW.row_id;

      SELECT ('x'||TRANSLATE(current_sheet_id::VARCHAR,'-',''))::BIT(64)::BIGINT INTO lock_id;

      SET LOCAL lock_timeout = '10s';
      PERFORM pg_advisory_lock(lock_id);

      SELECT COUNT(*) INTO pending
        FROM ingest_progress
        JOIN ingest_sheet_rows ON ingest_progress.row_id = ingest_sheet_rows.id
        WHERE ingest_sheet_rows.sheet_id = current_sheet_id
        AND ingest_progress.status NOT IN ('ok', 'error');

      IF pending = 0 THEN
        UPDATE ingest_sheets
        SET status = 'completed', updated_at = NOW() AT TIME ZONE 'utc'
        WHERE ingest_sheets.id = current_sheet_id;
      END IF;

      PERFORM pg_advisory_unlock(lock_id);

      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
    """

    execute """
    CREATE TRIGGER progress_update_sheet_status
      AFTER UPDATE OR DELETE
      ON ingest_progress
      FOR EACH ROW
      EXECUTE PROCEDURE update_sheet_status_when_progress_changes()
    """
  end

  def down do
    execute "DROP TRIGGER IF EXISTS progress_update_sheet_status ON ingest_progress;"
    execute "DROP FUNCTION IF EXISTS update_sheet_status_when_progress_changes;"
  end
end
