defmodule Meadow.Repo.Migrations.CreateProjectWorkAssociationTrigger do
  use Ecto.Migration

  def up do
    execute """
    CREATE OR REPLACE FUNCTION reindex_work_when_project_changes()
      RETURNS trigger AS $$
    BEGIN
      IF (TG_OP = 'DELETE') THEN
        UPDATE works
        SET updated_at = NOW()
        WHERE ingest_sheet_id IN (
          SELECT id
          FROM ingest_sheets
          WHERE project_id = OLD.id
        );
        RETURN OLD;
      ELSE
        UPDATE works
        SET updated_at = NOW()
        WHERE ingest_sheet_id IN (
          SELECT id
          FROM ingest_sheets
          WHERE project_id = NEW.id
        );
        RETURN NEW;
      END IF;
    END;
    $$ LANGUAGE plpgsql
    """

    execute """
    CREATE TRIGGER projects_work_reindex
      AFTER UPDATE OR DELETE
      ON projects
      FOR EACH ROW
      EXECUTE PROCEDURE reindex_work_when_project_changes()
    """
  end

  def down do
    execute "DROP TRIGGER IF EXISTS projects_work_reindex ON projects;"
    execute "DROP FUNCTION IF EXISTS reindex_work_when_project_changes;"
  end
end
