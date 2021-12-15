defmodule Meadow.Repo.Migrations.RecreateTriggers do
  use Ecto.Migration

  import Meadow.DatabaseNotification
  import Meadow.Utils.DependencyTriggers

  require Logger

  def up do
    drop_dependency_trigger(:ingest_sheets, :works)
    drop_dependency_trigger(:collections, :works)
    drop_dependency_trigger(:works, :file_sets)
    drop_dependency_trigger(:works, :collections)

    drop_parent_trigger(:works, :file_sets)
    drop_old_notification_trigger(:works)
    drop_old_notification_trigger(:ingest_sheets)
    drop_old_notification_trigger(:file_sets)

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

    create_notification_trigger(:works, :all)
    create_notification_trigger(:ingest_sheets, :all)
    create_notification_trigger(:file_sets, ["structural_metadata"])
    create_notification_trigger(:file_sets, :all, :works, :work_id)
  end

  def down do
    Logger.warn("Irreversible Migration")
  end
end
