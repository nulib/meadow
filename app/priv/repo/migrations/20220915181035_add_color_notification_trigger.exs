defmodule Meadow.Repo.Migrations.AddColorNotificationTrigger do
  use Ecto.Migration

  import Meadow.DatabaseNotification

  def up do
    create_notification_trigger(
      :file_sets,
      ["structural_metadata", "poster_offset", "dominant_color"],
      :works,
      :work_id
    )
  end

  def down do
    create_notification_trigger(
      :file_sets,
      ["structural_metadata", "poster_offset"],
      :works,
      :work_id
    )
  end
end
