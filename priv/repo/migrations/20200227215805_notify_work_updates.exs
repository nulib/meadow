defmodule Meadow.Repo.Migrations.NotifyWorkUpdates do
  use Ecto.Migration

  def up do
    execute """
    CREATE OR REPLACE FUNCTION notify_work_changes()
    RETURNS trigger AS $$
    BEGIN
    PERFORM pg_notify(
    'works_changed',
    json_build_object(
     'operation', TG_OP,
     'record', row_to_json(NEW)
    )::text
    );

    RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER works_changed
      AFTER INSERT OR UPDATE
      ON works
      FOR EACH ROW
      EXECUTE PROCEDURE notify_work_changes()
    """
  end

  def down do
    execute("DROP TRIGGER IF EXISTS works_changed ON works")
    execute("DROP FUNCTION IF EXISTS notify_work_changes")
  end
end
