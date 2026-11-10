defmodule Meadow.Embeddings.Worker do
  @moduledoc """
  Collects the ids of works whose metadata changed and embeds them in
  batches.

  Database events arrive in bursts (one work edit touches several tables,
  a batch edit touches thousands of works), so ids are deduplicated and
  held for a short interval before being processed.

  Supports the following init arguments:
  * `:interval` - how long to collect ids before embedding, in milliseconds (default: 2_000)
  * `:batch_size` - the maximum number of works embedded per run (default: 25)
  * `:max_attempts` - how many times a work is tried before it is dropped (default: 3)
  """

  use GenServer

  alias Meadow.Embeddings

  require Logger

  @interval 2_000
  @batch_size 25
  @max_attempts 3

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc "Queue works to have their embeddings refreshed"
  def enqueue(work_ids) when is_list(work_ids) do
    case {work_ids, server()} do
      {[], _} -> :ok
      {_, nil} -> :ok
      {_, server} -> GenServer.cast(server, {:enqueue, work_ids})
    end
  end

  @doc "Process everything queued right now. Returns the number of works still queued."
  def flush do
    case server() do
      nil -> 0
      server -> GenServer.call(server, :flush, :infinity)
    end
  end

  defp server do
    case Horde.Registry.whereis_name({Meadow.HordeRegistry, __MODULE__}) do
      pid when is_pid(pid) -> pid
      _ -> Process.whereis(__MODULE__)
    end
  end

  @impl true
  def init(opts) do
    {:ok,
     %{
       interval: Keyword.get(opts, :interval, @interval),
       batch_size: Keyword.get(opts, :batch_size, @batch_size),
       max_attempts: Keyword.get(opts, :max_attempts, @max_attempts),
       pending: %{},
       timer: nil
     }}
  end

  @impl true
  def handle_cast({:enqueue, work_ids}, state) do
    pending = Enum.reduce(work_ids, state.pending, &Map.put_new(&2, &1, 0))
    {:noreply, schedule(%{state | pending: pending})}
  end

  @impl true
  def handle_call(:flush, _from, state) do
    state = state |> cancel_timer() |> process_all()
    {:reply, map_size(state.pending), schedule(state)}
  end

  @impl true
  def handle_info(:process, state) do
    {:noreply, %{state | timer: nil} |> process_batch() |> schedule()}
  end

  # One pass over everything queued when the flush was requested; works that
  # fail stay queued for a later attempt.
  defp process_all(state) do
    state.pending
    |> Map.keys()
    |> Enum.chunk_every(state.batch_size)
    |> Enum.reduce(state, &process(&2, &1))
  end

  defp process_batch(state) do
    process(state, state.pending |> Map.keys() |> Enum.take(state.batch_size))
  end

  defp process(state, []), do: state

  defp process(state, work_ids) do
    case refresh(work_ids) do
      {:ok, _} -> %{state | pending: Map.drop(state.pending, work_ids)}
      {:error, reason} -> %{state | pending: retry(state, work_ids, reason)}
    end
  end

  defp refresh(work_ids) do
    Embeddings.refresh_works(work_ids)
  rescue
    exception -> {:error, exception}
  end

  defp retry(state, work_ids, reason) do
    Logger.error("Failed to embed #{length(work_ids)} works: #{inspect(reason)}")

    Enum.reduce(work_ids, state.pending, fn work_id, pending ->
      case Map.get(pending, work_id, 0) + 1 do
        attempts when attempts >= state.max_attempts ->
          Logger.error("Giving up on embedding for work #{work_id} after #{attempts} attempts")
          Map.delete(pending, work_id)

        attempts ->
          Map.put(pending, work_id, attempts)
      end
    end)
  end

  defp schedule(%{timer: nil, interval: interval, pending: pending} = state)
       when map_size(pending) > 0 and is_integer(interval) do
    %{state | timer: Process.send_after(self(), :process, interval)}
  end

  defp schedule(state), do: state

  defp cancel_timer(%{timer: nil} = state), do: state

  defp cancel_timer(%{timer: timer} = state) do
    Process.cancel_timer(timer)
    %{state | timer: nil}
  end
end
