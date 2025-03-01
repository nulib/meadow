defmodule Meadow.Events.Collections do
  @moduledoc """
  Handles Collection events for reindexing.
  """

  use WalEx.Event, name: Meadow

  on_insert(:collections, %{}, [{Meadow.Events.Indexing, :handle_insert}], & &1)
  on_update(:collections, %{}, [{Meadow.Events.Indexing, :handle_update}], & &1)
  on_delete(:collections, %{}, [{Meadow.Events.Indexing, :handle_delete}], & &1)
end
