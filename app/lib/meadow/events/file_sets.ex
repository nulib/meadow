defmodule Meadow.Events.FileSets do
  @moduledoc """
  Handles FileSet events for reindexing and AWS S3 cleanup.
  """

  use WalEx.Event, name: Meadow

  @filter %{unwatched_fields: [:reindex_at]}

  on_insert(:file_sets, @filter, [{Meadow.Events.Indexing, :handle_insert}], & &1)

  on_update(
    :file_sets,
    @filter,
    [
      {Meadow.Events.Indexing, :handle_update},
      {Meadow.Events.FileSets.StructuralMetadata, :write_structural_metadata}
    ],
    & &1
  )

  on_delete(
    :file_sets,
    %{},
    [{Meadow.Events.Indexing, :handle_delete}, {Meadow.Events.FileSetCleanup, :handle_delete}],
    & &1
  )
end
