defmodule Meadow.Repo.Migrations.WidenAiActivityEventItemIdentifier do
  @moduledoc """
  Make `ai_activity_events.item_identifier` hold an item of any length.

  A free-text item's provenance is keyed by the item's own text
  (`Meadow.AI.Provenance.item_identifier/1`), so the column has to take a whole
  description or abstract. Two things stopped it:

    * Some databases ran `20260626160000` from a version that declared the
      column `:string`, leaving it `varchar(255)` even though the merged
      migration says `:text`. Attesting a longer item there fails with
      `string_data_right_truncation`. Widening is lossless, and a no-op where
      the column is already `text`.

    * The column carried a plain btree index, which cannot hold an entry much
      past 2704 bytes, so attesting an item of a long abstract would have
      failed even with the column fixed. Nothing queries the column in SQL --
      per-item provenance loads a target's events and filters them in memory --
      so the index is dropped rather than replaced.
  """

  use Ecto.Migration

  def up do
    drop_if_exists(index(:ai_activity_events, [:item_identifier]))

    execute("ALTER TABLE ai_activity_events ALTER COLUMN item_identifier TYPE text")
  end

  # The column is deliberately left as `text`: narrowing it again would
  # truncate any item identifier longer than 255 characters.
  def down do
    create_if_not_exists(index(:ai_activity_events, [:item_identifier]))
  end
end
