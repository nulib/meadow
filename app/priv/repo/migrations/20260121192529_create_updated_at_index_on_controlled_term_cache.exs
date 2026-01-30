defmodule Meadow.Repo.Migrations.CreateUpdatedAtIndexOnControlledTermCache do
  use Ecto.Migration

  def change do
    create(index(:controlled_term_cache, [:updated_at]))
  end
end
