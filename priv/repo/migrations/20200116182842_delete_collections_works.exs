defmodule Meadow.Repo.Migrations.DeleteCollectionsWorks do
  use Ecto.Migration

  def change do
    alter table(:works) do
      add :collection_id, references(:collections, type: :binary_id)
    end

    drop index(:collections_works, [:collection_id, :work_id])
    drop table(:collections_works)
  end
end
