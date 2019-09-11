defmodule Meadow.Repo.Migrations.AddFileSetsTable do
  use Ecto.Migration

  def change do
    create table("file_sets", primary_key: false) do
      add(:id, :binary_id, null: false, primary_key: true)
      add :accession_number, :string
      add :metadata, :map
      add :work_id, references(:works, type: :binary_id)

      timestamps()
    end

    create unique_index("file_sets", [:accession_number])
  end
end
