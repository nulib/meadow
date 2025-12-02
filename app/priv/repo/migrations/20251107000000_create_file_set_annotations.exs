defmodule Meadow.Repo.Migrations.CreateFileSetAnnotations do
  use Ecto.Migration

  def change do
    create table(:file_set_annotations) do
      add(:file_set_id, references(:file_sets, on_delete: :delete_all), null: false)
      add(:type, :string, null: false)
      add(:language, {:array, :string})
      add(:model, :string)
      add(:s3_location, :string)
      add(:status, :string, null: false)

      timestamps()
    end

    create(index(:file_set_annotations, [:file_set_id]))
    create(index(:file_set_annotations, [:type]))
    create(index(:file_set_annotations, [:status]))
    create(unique_index(:file_set_annotations, [:file_set_id, :type]))
  end
end
