defmodule Meadow.Repo.Migrations.CreateWorkEmbeddings do
  use Ecto.Migration

  # EmbeddingGemma 2 native output size. Changing models means a new migration.
  @dimensions 768

  def up do
    execute("CREATE EXTENSION IF NOT EXISTS vector")

    create table(:work_embeddings, primary_key: false) do
      add(:work_id, references(:works, type: :binary_id, on_delete: :delete_all),
        primary_key: true
      )

      add(:model, :string, null: false)
      add(:text_hash, :string, null: false)
      add(:text_length, :integer, null: false)
      add(:embedding, :"vector(#{@dimensions})", null: false)
      timestamps()
    end

    create(index(:work_embeddings, [:model]))

    execute("ALTER PUBLICATION events ADD TABLE work_embeddings")
    execute("ALTER TABLE work_embeddings REPLICA IDENTITY FULL")
  end

  def down do
    execute("ALTER PUBLICATION events DROP TABLE work_embeddings")
    drop(table(:work_embeddings))
  end
end
