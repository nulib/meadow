defmodule Meadow.Repo.Migrations.AddFieldToWorks do
  use Ecto.Migration


  def change do
    alter table(:works) do
      add :behavior, :map, null: true, default: nil
    end
  end
end
