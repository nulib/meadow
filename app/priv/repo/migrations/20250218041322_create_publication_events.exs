defmodule Meadow.Repo.Migrations.CreatePublicationEvents do
  use Ecto.Migration

  def change do
    # Create the publication for WAL events
    execute "CREATE PUBLICATION events FOR ALL TABLES"

    # Set REPLICA IDENTITY FULL for tables we want to track
    execute "ALTER TABLE works REPLICA IDENTITY FULL"
    execute "ALTER TABLE file_sets REPLICA IDENTITY FULL"
    execute "ALTER TABLE collections REPLICA IDENTITY FULL"
    execute "ALTER TABLE ingest_sheets REPLICA IDENTITY FULL"
    execute "ALTER TABLE projects REPLICA IDENTITY FULL"
  end

  def down do
    # Reset REPLICA IDENTITY to default
    execute "ALTER TABLE works REPLICA IDENTITY DEFAULT"
    execute "ALTER TABLE file_sets REPLICA IDENTITY DEFAULT"
    execute "ALTER TABLE collections REPLICA IDENTITY DEFAULT"
    execute "ALTER TABLE ingest_sheets REPLICA IDENTITY DEFAULT"
    execute "ALTER TABLE projects REPLICA IDENTITY DEFAULT"

    execute "DROP PUBLICATION IF EXISTS events"
  end
end
