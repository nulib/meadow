defmodule Meadow.Repo.Migrations.CreateWorks do
  use Ecto.Migration

  def change do
    create table("works") do
      add(:collection_id, references(:collections, type: :binary_id))
      add(:ingest_sheet_id, references(:ingest_sheets, type: :binary_id, on_delete: :nilify_all))
      add(:accession_number, :string)
      add(:descriptive_metadata, :map, default: %{})
      add(:administrative_metadata, :map, default: %{})
      add(:published, :boolean)
      add(:visibility, :string)
      add(:work_type, :string)
      timestamps()
    end

    create(unique_index("works", [:accession_number]))
  end
end
