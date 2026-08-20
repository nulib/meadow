defmodule Meadow.Repo.Migrations.DropJsonbMetadataColumns do
  @moduledoc """
  Final step of the jsonb-to-relational cutover: drop the jsonb columns whose
  data now lives in relational tables (see the migrations that created
  `work_descriptive_metadata`, `file_set_core_metadata`,
  `ingest_sheet_row_fields` and `plan_change_operations`, and ADR 32).

  Forward-only: `down/0` re-adds the columns empty so older migrations can
  still be rolled back structurally, but the jsonb data is gone.
  """

  use Ecto.Migration

  require Logger

  @columns [
    {:works, :descriptive_metadata, :map},
    {:works, :administrative_metadata, :map},
    {:file_sets, :core_metadata, :map},
    {:file_sets, :structural_metadata, :map},
    {:file_sets, :extracted_metadata, :map},
    {:file_sets, :derivatives, :map},
    {:ingest_sheet_rows, :fields, :jsonb},
    {:ingest_sheet_rows, :errors, :jsonb},
    {:ingest_sheets, :state, :jsonb},
    {:plan_changes, :add, :jsonb},
    {:plan_changes, :delete, :jsonb},
    {:plan_changes, :replace, :jsonb},
    # never mapped by any schema
    {:plan_changes, :changeset, :jsonb}
  ]

  def up do
    Enum.each(@columns, fn {table, column, _type} ->
      alter table(table) do
        remove(column)
      end
    end)
  end

  def down do
    Logger.warning("Re-adding jsonb metadata columns empty; the original documents were dropped")

    Enum.each(@columns, fn {table, column, type} ->
      alter table(table) do
        add(column, type)
      end
    end)
  end
end
