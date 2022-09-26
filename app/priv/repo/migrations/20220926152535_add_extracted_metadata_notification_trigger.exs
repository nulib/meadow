defmodule Meadow.Repo.Migrations.AddExtractedMetadataNotificationTrigger do
  use Ecto.Migration

  import Meadow.DatabaseNotification

  def up do
    create_notification_trigger(
      :file_sets,
      ["structural_metadata", "poster_offset", "extracted_metadata"],
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
