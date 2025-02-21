defmodule Meadow.Events.Collections do
  @moduledoc """
  Handles Collection events for reindexing.
  """

  use WalEx.Event, name: Meadow

  @filter %{unwatched_fields: [:reindex_at]}

  on_insert(:collections, @filter, [{Meadow.Events.Indexing, :handle_insert}], & &1)
  on_update(:collections, @filter, [{Meadow.Events.Indexing, :handle_update}], & &1)
  on_delete(:collections, @filter, [{Meadow.Events.Indexing, :handle_delete}], & &1)
end
