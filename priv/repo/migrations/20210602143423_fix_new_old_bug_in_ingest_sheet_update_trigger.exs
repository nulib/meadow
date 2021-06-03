defmodule Meadow.Repo.Migrations.FixNewOldBugInIngestSheetUpdateTrigger do
  use Ecto.Migration

  def up do
    execute "DROP TRIGGER IF EXISTS progress_update_sheet_status ON ingest_progress;"
    execute """
    CREATE TRIGGER progress_update_sheet_status
      AFTER UPDATE
      ON ingest_progress
      FOR EACH ROW
      EXECUTE PROCEDURE update_sheet_status_when_progress_changes()
    """
  end

  def down do
    execute "DROP TRIGGER IF EXISTS progress_update_sheet_status ON ingest_progress;"
    execute """
    CREATE TRIGGER progress_update_sheet_status
      AFTER UPDATE OR DELETE
      ON ingest_progress
      FOR EACH ROW
      EXECUTE PROCEDURE update_sheet_status_when_progress_changes()
    """
  end
end
