defmodule Meadow.Repo.Migrations.PublishFileSetEmbeddings do
  use Ecto.Migration

  # File set embeddings are copied into the search index, so a write has to
  # raise a WalEx event that reindexes the file set
  def up do
    execute("ALTER PUBLICATION events ADD TABLE file_set_embeddings")
    execute("ALTER TABLE file_set_embeddings REPLICA IDENTITY FULL")
  end

  def down do
    execute("ALTER TABLE file_set_embeddings REPLICA IDENTITY DEFAULT")
    execute("ALTER PUBLICATION events DROP TABLE file_set_embeddings")
  end
end
