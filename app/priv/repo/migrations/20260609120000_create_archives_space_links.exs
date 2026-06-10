defmodule Meadow.Repo.Migrations.CreateArchivesSpaceLinks do
  use Ecto.Migration

  def change do
    create table(:archives_space_links, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: fragment("gen_random_uuid()"))

      # Intentionally not foreign keys: link rows must survive the deletion of
      # their work/collection so the remote ArchivesSpace cleanup can be
      # processed (and its failures surfaced) after the local record is gone.
      add(:work_id, :uuid)
      add(:collection_id, :uuid)

      add(:archives_space_uri, :string, null: false)
      add(:ref_id, :string)
      add(:repository_id, :integer)
      add(:digital_object_uri, :string)
      add(:sync_status, :string, null: false, default: "linked")
      add(:sync_error, :text)
      add(:last_synced_at, :utc_datetime_usec)
      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:archives_space_links, [:work_id]))
    create(unique_index(:archives_space_links, [:collection_id]))
    create(index(:archives_space_links, [:archives_space_uri]))
    create(index(:archives_space_links, [:sync_status]))

    create(
      constraint(:archives_space_links, :work_or_collection,
        check: "work_id IS NULL OR collection_id IS NULL"
      )
    )
  end
end
