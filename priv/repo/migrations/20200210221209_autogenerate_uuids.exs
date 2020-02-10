defmodule Meadow.Repo.Migrations.AutogenerateUuids do
  use Ecto.Migration

  @tables ~w[action_states collections file_sets works projects ingest_sheet_rows ingest_sheets]
  def up do
    execute(~s[CREATE EXTENSION IF NOT EXISTS "uuid-ossp"])

    @tables
    |> Enum.each(fn table ->
      alter table(table) do
        modify :id, :binary_id, default: {:fragment, "uuid_generate_v1()"}
      end
    end)
  end

  def down do
    @tables
    |> Enum.each(fn table ->
      alter table(table) do
        modify :id, :binary_id, default: nil
      end
    end)
  end
end
