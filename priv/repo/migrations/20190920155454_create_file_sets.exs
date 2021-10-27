defmodule Meadow.Repo.Migrations.CreateFileSets do
  use Ecto.Migration

  def change do
    create table(:file_sets) do
      add(:accession_number, :string)
      add(:role, :map)
      add(:core_metadata, :map, default: %{})
      add(:extracted_metadata, :map, default: %{})
      add(:structural_metadata, :map, default: %{})
      add(:derivatives, :map, default: %{})
      add(:work_id, references(:works, null: false, on_delete: :delete_all))
      add(:rank, :integer)
      add(:poster_offset, :integer)

      timestamps()
    end

    alter table(:works) do
      add(:representative_file_set_id, references(:file_sets, on_delete: :nilify_all))
    end

    create(unique_index(:file_sets, [:accession_number]))
    create(index(:file_sets, [:rank]))
    create(index(:file_sets, [:work_id]))
    create(index(:works, [:representative_file_set_id]))
  end
end
