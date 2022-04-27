defmodule Meadow.Repo.Migrations.LengthenBatchErrorField do
  use Ecto.Migration

  def up do
    alter table(:batches) do
      modify :error, :text
    end
  end

  def down do
    alter table(:batches) do
      modify :error, :string
    end
  end
end
