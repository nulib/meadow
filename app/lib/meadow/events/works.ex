defmodule Meadow.Events.Works do
  @moduledoc """
  Handles Work events reindexing and ARK management.
  """

  use WalEx.Event, name: Meadow

  @filter %{unwatched_fields: [:reindex_at]}

  on_insert(:works, @filter, [{Meadow.Events.Indexing, :handle_insert}, {Meadow.Events.Arks, :handle_insert}], & &1)
  on_update(:works, @filter, [{Meadow.Events.Indexing, :handle_update}, {Meadow.Events.Arks, :handle_update}], & &1)
  on_delete(:works, @filter, [{Meadow.Events.Indexing, :handle_delete}, {Meadow.Events.Arks, :handle_delete}], & &1)
end
