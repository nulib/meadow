defmodule Meadow.Data.IndexBatcher do
  @moduledoc """
  The IndexBatcher is a GenServer that batches documents for reindexing.
  """

  use GenServer

  use Meadow.Utils.Logging

  import Ecto.Query

  alias Meadow.Data.{Collections, Works}
  alias Meadow.Data.Schemas.{Collection, Work}
  alias Meadow.Repo
  alias Meadow.Search.Bulk
  alias Meadow.Search.Config, as: SearchConfig
  alias Meadow.Search.Document, as: SearchDocument

  require Logger

  @flush_interval 5_000

  def reindex(ids, schema) do
    target = String.to_existing_atom("#{schema}_batcher")
    send(target, {:reindex, ids})
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
    schema = Keyword.get(args, :schema)
    version = Keyword.get(args, :version, 2)
    {:ok, %{schema: schema, version: version, ids: MapSet.new([])}}
  end

  @impl GenServer
  def handle_info({:reindex, ids}, state) do
    state = cancel_timer(state)

    Map.update!(state, :ids, &MapSet.union(&1, MapSet.new(ids)))
    |> maybe_flush()
  end

  def handle_info(:flush, state), do: {:noreply, flush(state)}

  defp maybe_flush(state) do
    bulk_size =
      Application.get_env(:meadow, Meadow.Search.Cluster) |> Keyword.get(:bulk_size, 200)

    if MapSet.size(state.ids) >= bulk_size do
      {:noreply, flush(state)}
    else
      {:noreply, set_timer(state)}
    end
  end

  defp flush(state) do
    state = cancel_timer(state)
    ids = MapSet.to_list(state.ids)
    %{schema: schema, version: version} = state

    Logger.info("Flushing #{length(ids)} #{schema} documents")

    preloads = schema.required_index_preloads()

    from(doc in schema, where: doc.id in ^ids, preload: ^preloads)
    |> Repo.all()
    |> maybe_add_representative_image(schema)
    |> Enum.map(&encode_document(&1, version))
    |> Enum.reject(&(&1 == :skip))
    |> Bulk.upload(SearchConfig.alias_for(schema, version))

    Map.put(state, :ids, MapSet.new([]))
  end

  defp set_timer(state) do
    cancel_timer(state)
    |> Map.put(:timer_ref, Process.send_after(self(), :flush, @flush_interval))
  end

  defp cancel_timer(state) do
    case Map.get(state, :timer_ref) do
      nil -> :noop
      ref -> Process.cancel_timer(ref)
    end

    Map.put(state, :timer_ref, nil)
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
