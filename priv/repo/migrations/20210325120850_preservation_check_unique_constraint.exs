defmodule Meadow.Repo.Migrations.PreservationCheckUniqueConstraint do
  use Ecto.Migration

  def change do
    create_if_not_exists(unique_index(:preservation_checks, [:active], where: "active=true"))
  end
end
