defmodule Meadow.Repo.Migrations.ReplaceIndexTimesWithReindexAt do
  use Ecto.Migration

  import Meadow.Utils.DependencyTriggers

  require Logger

  def up do
    [:works, :file_sets, :collections]
    |> Enum.each(fn table ->
      execute "ALTER TABLE #{table} DISABLE TRIGGER USER"
      alter table(table), do: add(:reindex_at, :utc_datetime_usec)
      execute "ALTER TABLE #{table} ENABLE TRIGGER USER"
    end)

    drop_dependency_trigger(:file_sets, :works)
    drop_dependency_trigger(:ingest_sheets, :works)
    drop_dependency_trigger(:collections, :works)
    drop_dependency_trigger(:works, :file_sets)
    drop_dependency_trigger(:works, :collections)

    create_dependency_trigger(:ingest_sheets, :works, [:title])
    create_dependency_trigger(:collections, :works, [:title])
    create_dependency_trigger(:works, :file_sets, [:published, :visibility])

    create_dependency_trigger(
      :works,
      :collections,
      [:representative_file_set_id],
      :representative_work
    )

    create_parent_trigger(:works, :file_sets, [:core_metadata, :derivatives, :rank])
    drop table(:index_times)
  end

  def down do
    Logger.warn("Dependency trigger migration not reversible.")

    [:works, :file_sets, :collections]
    |> Enum.each(fn table ->
      execute "ALTER TABLE #{table} DISABLE TRIGGER USER"
      alter table(table), do: remove(:reindex_at)
      execute "ALTER TABLE #{table} ENABLE TRIGGER USER"
    end)

    create table(:index_times, primary_key: false) do
      add(:id, :binary_id, primary_key: true, null: false)
      add(:indexed_at, :utc_datetime_usec, null: false)
    end
  end
end
