defmodule Meadow.Repo.Migrations.RenameGettyTableForGeneralUse do
  use Ecto.Migration

  def up do
    rename(table(:getty_vocab), to: table(:local_vocabularies))

    execute(
      "ALTER TABLE local_vocabularies RENAME CONSTRAINT getty_vocab_pkey TO local_vocabularies_pkey;",
      "ALTER TABLE local_vocabularies RENAME CONSTRAINT local_vocabularies_pkey TO getty_vocab_pkey;"
    )

    execute(
      "ALTER INDEX getty_terms_label_trgm_index RENAME TO local_vocabularies_label_trgm_index;",
      "ALTER INDEX local_vocabularies_label_trgm_index RENAME TO getty_terms_label_trgm_index;"
    )

    execute(
      "ALTER INDEX getty_terms_variants_trgm_index RENAME TO local_vocabularies_variants_trgm_index;",
      "ALTER INDEX local_vocabularies_variants_trgm_index RENAME TO getty_terms_variants_trgm_index;"
    )
  end
end
