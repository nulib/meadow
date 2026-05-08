defmodule Meadow.Repo.Migrations.DropLocalAuthorities do
  use Ecto.Migration

  def up do
    drop table(:local_vocabularies)
  end
end
