defmodule Meadow.Repo.Migrations.AddFileSetAnnotationsToPublication do
  use Ecto.Migration

  def up do
    # Add file_set_annotations to the existing publication
    execute("ALTER PUBLICATION events ADD TABLE file_set_annotations")

    # Set REPLICA IDENTITY FULL so we get the old values in delete events
    execute("ALTER TABLE file_set_annotations REPLICA IDENTITY FULL")
  end

  def down do
    # Remove from publication
    execute("ALTER PUBLICATION events DROP TABLE file_set_annotations")

    # Reset REPLICA IDENTITY to default
    execute("ALTER TABLE file_set_annotations REPLICA IDENTITY DEFAULT")
  end
end
