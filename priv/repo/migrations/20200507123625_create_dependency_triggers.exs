defmodule Meadow.Repo.Migrations.CreateDependencyTriggers do
  use Ecto.Migration
  use Meadow.Utils.DependencyTriggers

  def up do
    create_dependency_trigger(:ingest_sheets, :works, [:title])
    create_dependency_trigger(:collections, :works, [:title])
    create_dependency_trigger(:works, :file_sets, [:published, :visibility])

    create_dependency_trigger(
      :works,
      :collections,
      [:representative_file_set_id],
      :representative_work
    )

    create_parent_trigger(:works, :file_sets, [:metadata, :rank])
  end

  def down do
    drop_dependency_trigger(:ingest_sheets, :works)
    drop_dependency_trigger(:collections, :works)
    drop_dependency_trigger(:works, :file_sets)
    drop_dependency_trigger(:works, :collections)

    drop_parent_trigger(:works, :file_sets)
  end
end
