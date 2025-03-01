defmodule Meadow.Events.Works do
  @moduledoc """
  Handles Work events reindexing and ARK management.
  """

  use WalEx.Event, name: Meadow

  on_insert(
    :works,
    %{},
    [{Meadow.Events.Indexing, :handle_insert}, {Meadow.Events.Arks, :handle_insert}],
    & &1
  )

  on_update(
    :works,
    %{},
    [{Meadow.Events.Indexing, :handle_update}, {Meadow.Events.Arks, :handle_update}],
    & &1
  )

  on_delete(
    :works,
    %{},
    [{Meadow.Events.Indexing, :handle_delete}, {Meadow.Events.Arks, :handle_delete}],
    & &1
  )
end
