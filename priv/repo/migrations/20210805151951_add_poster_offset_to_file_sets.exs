defmodule Meadow.Repo.Migrations.AddPosterOffsetToFileSets do
  use Ecto.Migration

  def up do
    alter table("file_sets") do
      add(:poster_offset, :integer)
    end
  end

  def down do
    alter table("file_sets") do
      remove(:poster_offset)
    end
  end
end
