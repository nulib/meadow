defmodule Meadow.Repo.Migrations.AddCollectionsWorksTable do
  use Ecto.Migration

  def change do
    create table(:collections_works, primary_key: false) do
      add :collection_id, references(:works, on_delete: :nothing)
      add :work_id, references(:collections, on_delete: :nothing)
    end

    create unique_index(:collections_works, [:collection_id, :work_id])
  end
end
