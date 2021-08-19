defmodule Meadow.Repo.Migrations.CreateFileSetCleanupTrigger do
  use Ecto.Migration

  def up do
    Ecto.Migration.execute("""
      CREATE OR REPLACE FUNCTION notify_file_sets_deleted()
      RETURNS trigger AS $$
      DECLARE
        ids UUID[];
        payload TEXT;
      BEGIN
        CREATE TEMPORARY TABLE notifications AS
          (SELECT DISTINCT id, jsonb_build_object('id', id, 'location', core_metadata -> 'location', 'derivatives', derivatives) AS data
          FROM old_table);

        SELECT array_agg(id) INTO ids FROM (SELECT id AS id FROM notifications LIMIT 20) AS notification_ids;
        WHILE array_length(ids, 1) > 0 LOOP
          SELECT jsonb_build_object('data', array_agg(data)) INTO payload FROM (SELECT data FROM notifications WHERE id = ANY(ids)) AS _data;
          PERFORM pg_notify('file_sets_deleted', payload);
          DELETE FROM notifications WHERE id = ANY(ids);
          SELECT array_agg(id) INTO ids FROM (SELECT id AS id FROM notifications LIMIT 20) AS notification_ids;
        END LOOP;
        DROP TABLE notifications;
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
    """)

    Ecto.Migration.execute("""
      CREATE TRIGGER file_sets_deleted
        AFTER DELETE ON file_sets
        REFERENCING OLD TABLE AS old_table
        FOR EACH STATEMENT
        EXECUTE PROCEDURE notify_file_sets_deleted()
    """)
  end

  def down do
    Ecto.Migration.execute("DROP TRIGGER IF EXISTS file_sets_deleted ON file_sets")
    Ecto.Migration.execute("DROP FUNCTION IF EXISTS notify_file_sets_deleted")
  end
end
