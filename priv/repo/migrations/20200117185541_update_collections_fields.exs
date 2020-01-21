defmodule Meadow.Repo.Migrations.UpdateCollectionsFields do
  use Ecto.Migration

  def change do
    alter table(:collections) do
      add :finding_aid_url, :text
      add :admin_email, :text
      add :featured, :boolean
    end
  end
end
