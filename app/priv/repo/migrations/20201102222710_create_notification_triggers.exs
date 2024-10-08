defmodule Meadow.Repo.Migrations.CreateNotificationTriggers do
  use Ecto.Migration

  import Meadow.DatabaseNotification

  def up do
    create_notification_trigger(:works, :all)
    create_notification_trigger(:ingest_sheets, :all)
    create_notification_trigger(:file_sets, ["structural_metadata"])
    create_notification_trigger(:file_sets, ["structural_metadata"], :works, :work_id)
  end

  def down do
    drop_notification_trigger(:works)
    drop_notification_trigger(:ingest_sheets)
    drop_notification_trigger(:file_sets)
    drop_notification_trigger(:file_sets, :works)
  end
end
