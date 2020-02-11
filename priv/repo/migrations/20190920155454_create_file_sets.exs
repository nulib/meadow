defmodule Meadow.Repo.Migrations.CreateFileSets do
  use Ecto.Migration

  def change do
    create table("file_sets") do
      add(:accession_number, :string)
      add(:role, :string)
      add(:metadata, :map)
      add(:work_id, references(:works, null: false, on_delete: :delete_all))
      add(:rank, :integer)

      timestamps()
    end

    create(unique_index(:file_sets, [:accession_number]))
    create(index(:file_sets, [:rank]))
  end
end
