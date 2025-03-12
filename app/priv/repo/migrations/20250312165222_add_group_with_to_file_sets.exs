defmodule Meadow.Repo.Migrations.AddGroupWithToFileSets do
  use Ecto.Migration

  def change do
    alter table(:file_sets) do
      add :group_with, references(:file_sets, type: :uuid, on_delete: :nilify_all)
    end

    create index(:file_sets, [:group_with])
  end
end
