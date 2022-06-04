defmodule Meadow.Repo.Migrations.ChangePublishedToCodedTerm do
  use Ecto.Migration

  @published %{id: "PUBLISHED", label: "Published", scheme: "published"}
  @unpublished %{id: "UNPUBLISHED", label: "Unpublished", scheme: "published"}
  @embargoed %{id: "EMBARGOED", label: "Embargoed", scheme: "published"}

  def up do
    rename table("works"), :published, to: :published_bool
    alter table("works"), do: add(:published, :map, default: @unpublished)
    flush()

    [
      "ALTER TABLE works DISABLE TRIGGER USER",
      fn ->
        repo().query!(
          "UPDATE works SET published = $1::json WHERE published_bool = true AND reading_room = false",
          [@published]
        )
      end,
      fn ->
        repo().query!(
          "UPDATE works SET published = $1::json WHERE reading_room = true",
          [@embargoed]
        )
      end,
      "ALTER TABLE works ENABLE TRIGGER USER"
    ]
    |> Enum.each(&execute/1)

    alter table("works") do
      remove :published_bool
      remove :reading_room
    end
  end

  def down do
    rename table("works"), :published, to: :published_map

    alter table("works") do
      add :published, :boolean, default: false
      add :reading_room, :boolean, default: false
    end

    flush()

    [
      "ALTER TABLE works DISABLE TRIGGER USER",
      "UPDATE works SET published = true WHERE published_map->>'id' IN ('EMBARGOED', 'PUBLISHED')",
      "UPDATE works SET reading_room = true WHERE published_map->>'id' = 'EMBARGOED'",
      "ALTER TABLE works ENABLE TRIGGER USER"
    ]
    |> Enum.each(&execute/1)

    alter table("works"), do: remove(:published_map)
  end
end
