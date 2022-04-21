defmodule Meadow.Repo.Migrations.CreateIngestSheets do
  use Ecto.Migration

  def change do
    create table(:ingest_sheets) do
      add(:title, :string)
      add(:filename, :string)
      add(:state, :jsonb)
      add(:status, :string)
      add(:file_errors, {:array, :text}, default: [])
      add(:project_id, references(:projects, on_delete: :delete_all))

      timestamps()
    end

    create(unique_index(:ingest_sheets, [:title]))
    create(index(:ingest_sheets, [:project_id]))
  end
end
