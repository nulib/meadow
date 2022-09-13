defmodule Meadow.Repo.Migrations.AddDominantColorToFileSets do
  use Ecto.Migration

  def change do
    alter table("file_sets") do
      add(:dominant_color, :map, default: %{})
    end
  end
end
