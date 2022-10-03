defmodule Meadow.Repo.Migrations.AddCollectionNotificationTrigger do
  use Ecto.Migration

  import Meadow.DatabaseNotification

  def up do
    create_notification_trigger(:collections, :all)
  end

  def down do
    drop_notification_trigger(:collections)
  end
end
