defmodule Meadow.Repo.Migrations.WorksChangedNotification do
  use Ecto.Migration
  import Meadow.DatabaseNotification

  def up do
    create_notification_trigger(:works)
  end

  def down do
    drop_notification_trigger(:works)
  end
end
