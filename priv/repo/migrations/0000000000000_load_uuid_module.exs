defmodule Meadow.Repo.Migrations.LoadUuidModule do
  use Ecto.Migration

  def up, do: execute(~s[CREATE EXTENSION IF NOT EXISTS "uuid-ossp"])
  def down, do: :noop
end
