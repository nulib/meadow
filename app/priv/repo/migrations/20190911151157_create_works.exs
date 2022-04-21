defmodule Meadow.Repo.Migrations.CreateWorks do
  use Ecto.Migration

  def change do
    create table(:works) do
      add(:collection_id, references(:collections, type: :binary_id))
      add(:ingest_sheet_id, references(:ingest_sheets, type: :binary_id, on_delete: :nilify_all))
      add(:accession_number, :string)
      add(:descriptive_metadata, :map, default: %{})
      add(:administrative_metadata, :map, default: %{})
      add(:published, :boolean)
      add(:visibility, :map)
      add(:work_type, :map)
      timestamps()
    end

    alter table(:collections) do
      add(:representative_work_id, references(:works, on_delete: :nilify_all))
    end

    create(unique_index(:works, [:accession_number]))
    create(index(:works, [:collection_id]))
    create(index(:works, [:ingest_sheet_id]))
    create(index(:collections, [:representative_work_id]))
  end
end
