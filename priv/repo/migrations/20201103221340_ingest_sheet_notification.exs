defmodule Meadow.Repo.Migrations.IngestSheetNotification do
  use Ecto.Migration
  import Meadow.DatabaseNotification


  def up do
    create_notification_trigger(:ingest_sheets)
  end

  def down do
    drop_notification_trigger(:ingest_sheets)
  end
end
