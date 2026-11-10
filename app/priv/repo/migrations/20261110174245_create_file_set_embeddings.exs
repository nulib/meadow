defmodule Meadow.Repo.Migrations.CreateFileSetEmbeddings do
  use Ecto.Migration

  # EmbeddingGemma 2 native output size. Changing models means a new migration.
  @dimensions 768

  def change do
    create table(:file_set_embeddings, primary_key: false) do
      add(:file_set_id, references(:file_sets, type: :binary_id, on_delete: :delete_all),
        primary_key: true
      )

      add(:model, :string, null: false)
      add(:soft_tokens, :integer, null: false)
      add(:embedding, :"vector(#{@dimensions})", null: false)
      timestamps()
    end

    create(index(:file_set_embeddings, [:model]))
  end
end
