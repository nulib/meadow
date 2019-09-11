defmodule Meadow.Repo.Migrations.AddWorksTable do
  use Ecto.Migration

  def change do
    create table("works", primary_key: false) do
      add(:id, :binary_id, null: false, primary_key: true)
      add :work_type, :string
      add :visibility, :string
      add :accession_number, :string
      add :metadata, :map

      timestamps()
    end

    create unique_index("works", [:accession_number])
  end
end
