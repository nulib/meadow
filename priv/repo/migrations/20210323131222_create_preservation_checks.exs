defmodule Meadow.Repo.Migrations.CreatePreservationChecks do
  use Ecto.Migration

  def change do
    create table("preservation_checks") do
      add(:filename, :string)
      add(:location, :string)
      add(:invalid_rows, :integer)
      add(:status, :string)
      add(:active, :boolean)
      timestamps()
    end
  end
end
