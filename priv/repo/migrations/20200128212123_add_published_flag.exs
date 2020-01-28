defmodule Meadow.Repo.Migrations.AddPublishedFlag do
  use Ecto.Migration

  def change do
    alter table(:works) do
      add :published, :boolean
    end

    alter table(:collections) do
      add :published, :boolean
    end
  end
end
