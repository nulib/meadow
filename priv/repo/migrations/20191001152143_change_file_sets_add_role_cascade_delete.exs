defmodule Meadow.Repo.Migrations.ChangeFileSetsAddRoleCascadeDelete do
  use Ecto.Migration

  def change do
    drop(constraint(:file_sets, "file_sets_work_id_fkey"))

    alter table(:file_sets) do
      add :role, :string
      modify :work_id, references(:works, null: false, on_delete: :delete_all)
    end
  end
end
