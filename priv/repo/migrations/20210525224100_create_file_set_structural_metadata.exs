defmodule Meadow.Repo.Migrations.CreateFileSetStructuralMetadata do
  use Ecto.Migration
  import Meadow.DatabaseNotification

  def up do
    alter table("file_sets"), do: add :structural_metadata, :map, default: %{}
    create_notification_trigger(:row, :file_sets, ["structural_metadata"])
  end

  def down do
    drop_notification_trigger(:file_sets)
    alter table("file_sets"), do: remove :structural_metadata, :map, default: %{}
  end
end
