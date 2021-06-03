defmodule Meadow.Repo.Migrations.DefaultFileSetDerivativesEmptyMap do
  use Ecto.Migration

  def up do
    execute"""
    ALTER TABLE file_sets ALTER COLUMN derivatives SET DEFAULT '{}'::jsonb;
    """

    execute"""
    UPDATE file_sets
    SET derivatives = '{}'::jsonb
    WHERE derivatives IS NULL;
    """
  end

  def down do
    execute"""
    ALTER TABLE file_sets ALTER COLUMN derivatives DROP DEFAULT
    """
  end
end
