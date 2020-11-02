defmodule Meadow.Repo.Migrations.WorksChangedNotification do
  use Ecto.Migration
  import Meadow.DatabaseNotification

  # This is a cleanup function and should be removed during the next
  # migration rollup
  defp revert_20200227215805_notify_work_updates do
    execute("DROP TRIGGER IF EXISTS works_changed ON works")
    execute("DROP FUNCTION IF EXISTS notify_work_changes")
  end

  def up do
    revert_20200227215805_notify_work_updates()
    flush()
    create_notification_trigger(:works)
  end

  def down do
    drop_notification_trigger(:works)
  end
end
