defmodule Meadow.Events.Works.Embeddings do
  @moduledoc """
  Handles events that can change the text a work is embedded from, and
  queues the affected works for embedding.

  The stored embedding is only regenerated when the text really changed
  (see `Meadow.Embeddings.refresh_works/1`), so this module errs on the side
  of queueing. Writing the embedding raises its own event, which
  `Meadow.Events.Indexing` uses to reindex the work.
  """

  use WalEx.Event, name: Meadow

  import Ecto.Query

  alias Meadow.Data.Schemas.Work
  alias Meadow.Embeddings
  alias Meadow.Embeddings.Worker
  alias Meadow.Events.Indexing

  on_event(:all, fn events -> handle_events(events) end)

  @doc "Queue the works affected by a list of database events"
  def handle_events(events) do
    if Embeddings.enabled?() do
      events
      |> Enum.flat_map(&affected_work_ids/1)
      |> Enum.uniq()
      |> Worker.enqueue()
    else
      :noop
    end
  end

  @doc "The ids of the works whose embedding text an event may have changed"
  def affected_work_ids(%{type: :insert, name: :works, new_record: %{id: id}}), do: [id]

  # The collection title is part of the embedding text
  def affected_work_ids(%{type: :update, name: :works, new_record: %{id: id}, changes: changes}) do
    if is_map(changes) and Map.has_key?(changes, :collection_id), do: [id], else: []
  end

  def affected_work_ids(%{type: :update, name: :collections, new_record: %{id: id}} = event) do
    if Map.has_key?(Map.get(event, :changes) || %{}, :title) do
      repo = Application.get_env(:meadow, :indexing_repo, Meadow.Repo)
      repo.all(from(w in Work, where: w.collection_id == ^id, select: w.id))
    else
      []
    end
  end

  def affected_work_ids(%{type: :delete, name: name, old_record: %{work_id: work_id}}) do
    if name in Indexing.work_metadata_tables(), do: [work_id], else: []
  end

  def affected_work_ids(%{name: name, new_record: %{work_id: work_id}}) do
    if name in Indexing.work_metadata_tables(), do: [work_id], else: []
  end

  def affected_work_ids(_), do: []
end
