defmodule Meadow.Repo.Migrations.CreateWorks do
  use Ecto.Migration

  def change do
    create table("works") do
      add(:work_type, :string)
      add(:collection_id, references(:collections, type: :binary_id))
      add(:visibility, :string)
      add(:accession_number, :string)
      add(:descriptive_metadata, :map)
      add(:administrative_metadata, :map)
      add(:published, :boolean)
      timestamps()
    end

    create(unique_index("works", [:accession_number]))
  end
end
