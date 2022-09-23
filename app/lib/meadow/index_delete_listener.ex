defmodule Meadow.IndexDeleteListener do
  @moduledoc """
  Database listener to synchronize deletes across search indexes
  """

  use GenServer
  require Logger

  alias Meadow.Data.Schemas.{Collection, FileSet, Work}
  alias Meadow.Search.{Bulk, Index}
  alias Meadow.Search.Config, as: SearchConfig

  @flush_interval 5_000

  @schema_tables %{"collections" => Collection, "file_sets" => FileSet, "works" => Work}

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(args) do
    for table <- Map.keys(@schema_tables) do
      Logger.info("#{__MODULE__}: Listening for changes to '#{table}'")

      with repo <- Keyword.get(args, :repo, Meadow.Repo) do
        repo.listen("#{table}_changed")
      end
    end

    {:ok, %{deletes: []}}
  end

  @impl GenServer
  def handle_info({:notification, _pid, _ref, message, payload}, state) do
    %{"ids" => ids, "source" => source, "operation" => operation} = Jason.decode!(payload)

    case {operation, String.trim_trailing(message, "_changed")} do
      {"DELETE", ^source} ->
        {:noreply, state |> add_to_state(source, ids) |> maybe_flush()}

      _ ->
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info(:flush, state) do
    Logger.info("Flushing #{length(state.deletes)} deleted documents from index")

    for {table, ids} <- deletes_by_schema(state) do
      delete_ids(table, ids)
    end

    new_state =
      state
      |> Map.put(:deletes, [])
      |> Map.delete(:flush_timer)

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info(_, state), do: {:noreply, state}

  defp add_to_state(state, table, ids) do
    new_deletes = Enum.reduce(ids, [], fn id, acc -> [{table, id} | acc] end)

    state
    |> Map.update(:deletes, new_deletes, fn deletes -> new_deletes ++ deletes end)
  end

  defp maybe_flush(state) do
    cond do
      length(state.deletes) >= SearchConfig.bulk_page_size() ->
        send(self(), :flush)
        state

      Map.get(state, :flush_timer) ->
        state

      true ->
        Process.send_after(self(), :flush, @flush_interval)
        Map.put(state, :flush_timer, true)
    end
  end

  defp deletes_by_schema(%{deletes: deletes}) do
    deletes
    |> Enum.group_by(
      fn {table, _id} -> table end,
      fn {_table, id} -> id end
    )
  end

  defp delete_ids(table, ids) do
    with schema <- Map.get(@schema_tables, table) do
      Enum.each(SearchConfig.index_versions(), fn version ->
        alias = SearchConfig.alias_for(schema, version)
        Bulk.delete(ids, alias)
        Index.refresh(alias)
      end)
    end
  end
end
