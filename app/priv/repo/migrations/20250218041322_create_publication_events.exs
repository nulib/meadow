defmodule Meadow.Repo.Migrations.CreatePublicationEvents do
  use Ecto.Migration

  @tables ~w(works file_sets collections ingest_sheets projects)

  def up do
    # Create the publication for WAL events
    execute("CREATE PUBLICATION events FOR TABLE #{Enum.join(@tables, ", ")}")

    # Set REPLICA IDENTITY FULL for tables we want to track
    Enum.each(@tables, fn table ->
      execute("ALTER TABLE #{table} REPLICA IDENTITY FULL")
    end)
  end

  def down do
    # Reset REPLICA IDENTITY to default
    Enum.each(@tables, fn table ->
      execute("ALTER TABLE #{table} REPLICA IDENTITY FULL")
    end)

    execute("DROP PUBLICATION IF EXISTS events")
  end
end
