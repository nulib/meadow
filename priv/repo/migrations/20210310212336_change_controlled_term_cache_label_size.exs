defmodule Meadow.Repo.Migrations.ChangeControlledTermCacheLabelSize do
  use Ecto.Migration

  def up do
    alter table(:controlled_term_cache) do
      modify :label, :text
    end
  end

  def down do
    execute("TRUNCATE controlled_term_cache")

    alter table(:controlled_term_cache) do
      modify :label, :string
    end
  end
end
