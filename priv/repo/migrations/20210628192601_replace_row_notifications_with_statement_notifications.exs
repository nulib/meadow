defmodule Meadow.Repo.Migrations.ReplaceRowNotificationsWithStatementNotifications do
  use Ecto.Migration

  import Meadow.DatabaseNotification

  def up do
    drop_notification_trigger(:works)
    drop_notification_trigger(:ingest_sheets)
    drop_notification_trigger(:file_sets)
    create_notification_trigger(:statement, :works, :all)
    create_notification_trigger(:statement, :ingest_sheets, :all)
    create_notification_trigger(:statement, :file_sets, ["structural_metadata"])
  end

  def down do
    drop_notification_trigger(:works)
    drop_notification_trigger(:ingest_sheets)
    drop_notification_trigger(:file_sets)
    create_notification_trigger(:row, :works, :all)
    create_notification_trigger(:row, :ingest_sheets, :all)
    create_notification_trigger(:row, :file_sets, ["structural_metadata"])
  end
end
