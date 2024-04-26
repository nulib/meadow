defmodule Meadow.Repo.Migrations.AddFieldsToBatches do
  use Ecto.Migration

  def change do
    alter table(:batches) do
      add :expected_deletes, :integer
      add :actual_deletes, :integer
    end
  end
end
