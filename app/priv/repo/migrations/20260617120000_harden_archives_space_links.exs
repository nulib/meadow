defmodule Meadow.Repo.Migrations.HardenArchivesSpaceLinks do
  use Ecto.Migration

  def change do
    alter table(:archives_space_links) do
      add(:sync_state, :map, null: false, default: fragment("'{}'::jsonb"))
    end

    create(
      unique_index(:archives_space_links, [:archives_space_uri],
        where: "work_id IS NOT NULL",
        name: :archives_space_links_work_archives_space_uri_index
      )
    )

    create(
      unique_index(:archives_space_links, [:archives_space_uri],
        where: "collection_id IS NOT NULL",
        name: :archives_space_links_collection_archives_space_uri_index
      )
    )
  end
end
