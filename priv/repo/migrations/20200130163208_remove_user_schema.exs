defmodule Meadow.Repo.Migrations.RemoveUserSchema do
  use Ecto.Migration

  def change do
    drop table(:users)
  end
end
