defmodule Meadow.Repo.Migrations.FeaturedFlagNotNull do
  use Ecto.Migration

  def up do
    execute "UPDATE collections SET featured = false WHERE featured IS NULL;"

    alter table(:collections) do
      modify :featured, :boolean, null: false, default: false
    end
  end

  def down do
    alter table(:collections) do
      modify :featured, :boolean, null: true, default: nil
    end
  end
end
