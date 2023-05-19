defmodule Meadow.Repo.Migrations.WorkRemoveReadingRoom do
  use Ecto.Migration

  def up do
    alter table(:works) do
      remove(:reading_room)
    end
  end

  def down do
    alter table(:works) do
      add(:reading_room, :boolean, default: false, null: false)
    end
  end
end
