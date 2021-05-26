defmodule Meadow.Repo.Migrations.AddDerivativesToFilesets do
  use Ecto.Migration

  def up do
    alter table("file_sets") do
      add(:derivatives, :map)
    end
  end

  def down do
    alter table("file_sets") do
      remove(:derivatives)
    end
  end
end
