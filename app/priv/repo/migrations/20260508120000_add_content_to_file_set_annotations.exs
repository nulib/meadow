defmodule Meadow.Repo.Migrations.AddContentToFileSetAnnotations do
  use Ecto.Migration

  def up do
    execute("CREATE EXTENSION IF NOT EXISTS pg_trgm", "")

    alter table(:file_set_annotations) do
      add :content, :text
    end

    execute(
      "CREATE INDEX file_set_annotations_content_trgm_idx ON file_set_annotations USING gin (content gin_trgm_ops)",
      "DROP INDEX IF EXISTS file_set_annotations_content_trgm_idx"
    )
  end

  def down do
    execute("DROP INDEX IF EXISTS file_set_annotations_content_trgm_idx", "")

    alter table(:file_set_annotations) do
      remove :content
    end
  end
end
