defmodule Meadow.Repo.Migrations.AddTemporaryGettyTable do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS pg_trgm;", "")

    create table(:getty_vocab, primary_key: false) do
      add(:authority, :string, primary_key: true)
      add(:uri, :string, primary_key: true)
      add(:label, :string)
      add(:hint, :string)
      add(:qualified_label, :string)
      add(:variants, :text)
    end

    execute(
      "CREATE INDEX getty_terms_label_trgm_index ON getty_vocab USING GIN (label gin_trgm_ops);",
      "DROP INDEX getty_terms_label_trgm_index;"
    )

    execute(
      "CREATE INDEX getty_terms_variants_trgm_index ON getty_vocab USING GIN (variants gin_trgm_ops);",
      "DROP INDEX getty_terms_variants_trgm_index;"
    )
  end
end
