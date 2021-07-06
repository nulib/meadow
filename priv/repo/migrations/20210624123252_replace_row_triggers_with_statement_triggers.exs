defmodule Meadow.Repo.Migrations.ReplaceRowTriggersWithStatementTriggers do
  use Ecto.Migration

  alias Meadow.Utils.DependencyTriggers.ForEachRow, as: RowTriggers
  alias Meadow.Utils.DependencyTriggers.ForEachStatement, as: StatementTriggers

  def up do
    RowTriggers.drop_parent_trigger(:works, :file_sets)
    RowTriggers.drop_dependency_trigger(:works, :collections)
    RowTriggers.drop_dependency_trigger(:works, :file_sets)
    RowTriggers.drop_dependency_trigger(:collections, :works)
    RowTriggers.drop_dependency_trigger(:ingest_sheets, :works)

    StatementTriggers.create_dependency_trigger(:ingest_sheets, :works, [:title])
    StatementTriggers.create_dependency_trigger(:collections, :works, [:title])
    StatementTriggers.create_dependency_trigger(:works, :file_sets, [:published, :visibility])

    StatementTriggers.create_dependency_trigger(
      :works,
      :collections,
      [:representative_file_set_id],
      :representative_work
    )

    StatementTriggers.create_parent_trigger(:works, :file_sets, [:core_metadata, :rank])
  end

  def down do
    StatementTriggers.drop_parent_trigger(:works, :file_sets)
    StatementTriggers.drop_dependency_trigger(:works, :collections)
    StatementTriggers.drop_dependency_trigger(:works, :file_sets)
    StatementTriggers.drop_dependency_trigger(:collections, :works)
    StatementTriggers.drop_dependency_trigger(:ingest_sheets, :works)

    RowTriggers.create_dependency_trigger(:ingest_sheets, :works, [:title])
    RowTriggers.create_dependency_trigger(:collections, :works, [:title])
    RowTriggers.create_dependency_trigger(:works, :file_sets, [:published, :visibility])

    RowTriggers.create_dependency_trigger(
      :works,
      :collections,
      [:representative_file_set_id],
      :representative_work
    )

    RowTriggers.create_parent_trigger(:works, :file_sets, [:core_metadata, :rank])
  end
end
