defmodule Meadow.Repo.Migrations.BatchNotifications do
  use Ecto.Migration
  import Meadow.DatabaseNotification

  def up do
    create_notification_trigger(:batches)
  end

  def down do
    drop_notification_trigger(:batches)
  end
end
