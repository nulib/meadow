defmodule Meadow.Repo.Migrations.CreateWorks do
  use Ecto.Migration

  def change do
    create table("works") do
      add(:collection_id, references(:collections, type: :binary_id))
      add(:accession_number, :string)
      add(:descriptive_metadata, :map, default: %{})
      add(:administrative_metadata, :map, default: %{})
      add(:published, :boolean)
      timestamps()
    end

    create(unique_index("works", [:accession_number]))
  end
end
