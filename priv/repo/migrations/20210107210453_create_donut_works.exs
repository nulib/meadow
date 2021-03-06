defmodule Meadow.Repo.Migrations.CreateDonutWorks do
  use Ecto.Migration

  def change do
    create table(:donut_works, primary_key: false) do
      add :work_id, :binary_id, primary_key: true
      add :manifest, :string, null: false
      add :last_modified, :utc_datetime, null: false
      add :status, :string
      add :error, :string

      timestamps()
    end
  end
end
