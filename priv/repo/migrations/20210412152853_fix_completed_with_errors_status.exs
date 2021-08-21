defmodule Meadow.Repo.Migrations.FixCompletedWithErrorsStatus do
  use Ecto.Migration

  require Logger

  def up do
    execute """
    CREATE OR REPLACE FUNCTION update_sheet_status_when_progress_changes()
      RETURNS trigger AS $$
    DECLARE
      current_sheet_id ingest_sheets.id%TYPE;
      lock_id bigint;
      pending integer;
      errors integer;
      complete_status varchar;
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
        SELECT COUNT(*) INTO errors
          FROM ingest_progress
          JOIN ingest_sheet_rows ON ingest_progress.row_id = ingest_sheet_rows.id
          WHERE ingest_sheet_rows.sheet_id = current_sheet_id
          AND ingest_progress.status = 'error';

        IF errors > 0 THEN
          SELECT 'completed_error' INTO complete_status;
        ELSE
          SELECT 'completed' INTO complete_status;
        END IF;

        UPDATE ingest_sheets
        SET status = complete_status, updated_at = NOW() AT TIME ZONE 'utc'
        WHERE ingest_sheets.id = current_sheet_id;
      END IF;

      PERFORM pg_advisory_unlock(lock_id);

      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
    """
  end

  def down do
    execute """
    CREATE OR REPLACE FUNCTION update_sheet_status_when_progress_changes()
      RETURNS trigger AS $$
    DECLARE
      current_sheet_id ingest_sheets.id%TYPE;
      lock_id bigint;
      pending integer;
      errors integer;
      complete_status varchar;
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
        SELECT COUNT(*) INTO errors
          FROM ingest_progress
          JOIN ingest_sheet_rows ON ingest_progress.row_id = ingest_sheet_rows.id
          WHERE ingest_sheet_rows.sheet_id = current_sheet_id
          AND ingest_progress.status IN ('ok', 'error');

        IF errors > 0 THEN
          SELECT 'completed_error' INTO complete_status;
        ELSE
          SELECT 'completed' INTO complete_status;
        END IF;

        UPDATE ingest_sheets
        SET status = complete_status, updated_at = NOW() AT TIME ZONE 'utc'
        WHERE ingest_sheets.id = current_sheet_id;
      END IF;

      PERFORM pg_advisory_unlock(lock_id);

      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
    """
  end
end
