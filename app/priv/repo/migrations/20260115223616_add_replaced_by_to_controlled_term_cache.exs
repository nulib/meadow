defmodule Meadow.Repo.Migrations.AddReplacedByToControlledTermCache do
  use Ecto.Migration

  def change do
    alter table(:controlled_term_cache) do
      add :replaced_by, :string, null: true
    end

    create index(:controlled_term_cache, [:replaced_by])
  end
end
