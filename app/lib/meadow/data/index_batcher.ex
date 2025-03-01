defmodule Meadow.Data.IndexBatcher do
  @moduledoc """
  The IndexBatcher is a GenServer that batches documents for reindexing.
  """

  use GenServer

  use Meadow.Utils.Logging

  import Ecto.Query

  alias Meadow.Data.{Collections, Works}
  alias Meadow.Data.Schemas.{Collection, Work}
  alias Meadow.Search.Bulk
  alias Meadow.Search.Config, as: SearchConfig
  alias Meadow.Search.Document, as: SearchDocument

  require Logger

  @flush_interval 5_000

  def delete(ids, schema) do
    target = String.to_existing_atom("#{schema}_batcher")
    GenServer.call(target, {:delete, ids}, :infinity)
  end

  def reindex(ids, schema) do
    target = String.to_existing_atom("#{schema}_batcher")
    GenServer.call(target, {:reindex, ids}, :infinity)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: Keyword.get(args, :name, __MODULE__))
  end

  @impl GenServer
  def init(args) do
    repo = Keyword.get(args, :repo, Meadow.Repo.Indexing)
    schema = Keyword.get(args, :schema)
    version = Keyword.get(args, :version, 2)

    {:ok,
     %{
       repo: repo,
       schema: schema,
       version: version,
       delete: MapSet.new([]),
       update: MapSet.new([]),
       timer_refs: []
     }}
  end

  @impl GenServer
  def handle_call({:delete, ids}, _from, state) do
    state = cancel_timer(state, :delete)

    Map.update!(state, :delete, &MapSet.union(&1, MapSet.new(ids)))
    |> maybe_flush(:delete)
  end

  @impl GenServer
  def handle_call({:reindex, ids}, _from, state) do
    state = cancel_timer(state, :update)

    Map.update!(state, :update, &MapSet.union(&1, MapSet.new(ids)))
    |> maybe_flush(:update)
  end

  @impl GenServer
  def handle_call({:flush, action}, _from, state), do: {:reply, :ok, flush(state, action)}

  @impl GenServer
  def handle_info({:flush, action}, state), do: {:noreply, flush(state, action)}

  defp maybe_flush(state, action) do
    if Map.get(state, action, MapSet.new()) |> MapSet.size() >= SearchConfig.bulk_page_size() do
      send(self(), {:flush, action})
      {:reply, :ok, cancel_timer(state, action)}
    else
      {:reply, :ok, set_timer(state, action)}
    end
  end

  defp flush(state, :delete) do
    state = cancel_timer(state, :delete)
    %{schema: schema, version: version} = state

    ids = MapSet.to_list(state.delete)
    if length(ids) > 0, do: Logger.info("Flushing #{length(ids)} #{schema} deleted documents")
    Bulk.delete(ids, SearchConfig.alias_for(schema, version))

    Map.put(state, :delete, MapSet.new([]))
  end

  defp flush(state, :update) do
    state = cancel_timer(state, :update)
    %{repo: repo, schema: schema, version: version} = state

    ids = MapSet.to_list(state.update)
    if length(ids) > 0, do: Logger.info("Flushing #{length(ids)} #{schema} updated documents")
    preloads = schema.required_index_preloads()

    ids
    |> Enum.chunk_every(SearchConfig.bulk_page_size())
    |> Enum.each(fn page ->
      from(doc in schema, where: doc.id in ^page, preload: ^preloads)
      |> repo.all()
      |> maybe_add_representative_image(schema)
      |> Enum.map(&encode_document(&1, version))
      |> Enum.reject(&(&1 == :skip))
      |> Bulk.upload(SearchConfig.alias_for(schema, version))
    end)

    Map.put(state, :update, MapSet.new([]))
  end

  defp set_timer(state, action) do
    cancel_timer(state, action)
    |> put_in(
      [:timer_refs, action],
      Process.send_after(self(), {:flush, action}, @flush_interval)
    )
  end

  defp cancel_timer(state, action) do
    case get_in(state, [:timer_refs, action]) do
      nil -> :noop
      ref -> Process.cancel_timer(ref)
    end

    put_in(state, [:timer_refs, action], nil)
  end

  defp encode_document(nil, _), do: :skip

  defp encode_document(item, version) do
    SearchDocument.encode(item, version)
  rescue
    e ->
      with_log_metadata module: __MODULE__, id: item.id do
        ("Index encoding failed due to: " <> Exception.format_banner(:error, e, []))
        |> Logger.error()
      end

      :skip
  end

  def maybe_add_representative_image(items, Collection),
    do: Enum.map(items, &Collections.add_representative_image/1)

  def maybe_add_representative_image(items, Work),
    do: Enum.map(items, &Works.add_representative_image/1)

  def maybe_add_representative_image(items, _), do: items
end
