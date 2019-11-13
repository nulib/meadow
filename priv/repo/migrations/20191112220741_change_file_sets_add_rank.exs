defmodule Meadow.Repo.Migrations.ChangeFileSetsAddRank do
  use Ecto.Migration

  def change do
    alter table(:file_sets) do
      add :rank, :integer
    end

    create(index(:file_sets, [:rank]))
  end
end
