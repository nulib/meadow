defmodule Meadow.Repo.Migrations.ChangeWorksTableAddAdminMetadata do
  use Ecto.Migration

  def change do
    rename table("works"), :metadata, to: :descriptive_metadata

    alter table("works") do
      add :administrative_metadata, :map
    end
  end
end
