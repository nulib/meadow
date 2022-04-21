defmodule Meadow.Repo.Migrations.WorksAddReadingRoom do
  use Ecto.Migration

  def change do
    alter table("works") do
      add :reading_room, :boolean, default: false, null: false
    end
  end
end
