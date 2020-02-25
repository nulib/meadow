defmodule Meadow.Repo.Migrations.CreateSheetWorkAssociationTrigger do
  use Ecto.Migration

  def up do
    execute """
    CREATE OR REPLACE FUNCTION reindex_work_when_sheet_changes()
      RETURNS trigger AS $$
    BEGIN
      IF (TG_OP = 'DELETE') THEN
        UPDATE works SET updated_at = NOW() WHERE id = OLD.work_id;
        RETURN OLD;
      ELSE
        UPDATE works SET updated_at = NOW() WHERE id = NEW.work_id;
        RETURN NEW;
      END IF;
    END;
    $$ LANGUAGE plpgsql
    """

    execute """
    CREATE TRIGGER sheet_works_work_reindex
      AFTER INSERT OR UPDATE OR DELETE
      ON ingest_sheet_works
      FOR EACH ROW
      EXECUTE PROCEDURE reindex_work_when_sheet_changes()
    """
  end

  def down do
    execute "DROP TRIGGER IF EXISTS sheet_works_work_reindex ON ingest_sheet_works;"
    execute "DROP FUNCTION IF EXISTS reindex_work_when_sheet_changes;"
  end
end
