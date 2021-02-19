defmodule Meadow.Repo.Migrations.CreateWorksBatches do
    use Ecto.Migration

    def change do
      create table(:works_batches, primary_key: false) do
        add(:work_id, references(:works, on_delete: :delete_all, type: :binary_id), primary_key: true)
        add(:batch_id, references(:batches, on_delete: :delete_all, type: :binary_id), primary_key: true)
        timestamps()
      end

      create(index(:works_batches, [:work_id]))
      create(index(:works_batches, [:batch_id]))

      create(
        unique_index(:works_batches, [:work_id, :batch_id], name: :work_id_batch_id_unique_index)
      )
    end
  end
