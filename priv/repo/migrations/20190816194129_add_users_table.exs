defmodule Meadow.Repo.Migrations.AddUsersTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :email, :string
      add :display_name, :string

      timestamps()
    end

    create unique_index(:users, [:username])
  end
end
