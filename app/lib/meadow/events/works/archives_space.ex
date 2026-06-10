defmodule Meadow.Events.Works.ArchivesSpace do
  @moduledoc """
  Pushes changes to linked works to ArchivesSpace

  Listens to WAL events on the `works` table and, for works linked to an
  ArchivesSpace record, schedules a metadata sync when a synced field
  changes and remote cleanup when the work is deleted. Sync status is
  recorded on the `archives_space_links` table (which has no WAL
  subscription, so status writes can never re-trigger sync events).
  """

  defmodule Processor do
    @moduledoc """
    Rate-limited processor for ArchivesSpace sync events.

    Supports the following init arguments:
    * `:token_count` - the maximum number of sync requests to process in a given interval (default: 10)
    * `:interval` - the interval in milliseconds over which to process the maximum number of sync requests (default: 1_000)
    * `:replenish_count` - the number of tokens added back to the pool per replenishment (default: `:token_count`)
    * `:replenish_interval` - the replenishment interval in milliseconds (default: `:interval`)
    """
    use GenServer

    alias Meadow.ArchivesSpace.Sync

    use Meadow.Utils.Logging

    require Logger

    @token_count 10
    @interval 1_000

    # Client API
    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, opts, name: __MODULE__)
    end

    def sync_work(work_id), do: GenServer.cast(__MODULE__, {:sync_work, work_id})
    def remove_work(work_id), do: GenServer.cast(__MODULE__, {:remove_work, work_id})

    # Server callbacks
    def init(init_arg) do
      token_count = Keyword.get(init_arg, :token_count, @token_count)
      interval = Keyword.get(init_arg, :interval, @interval)
      replenish_count = Keyword.get(init_arg, :replenish_count, token_count)
      replenish_interval = Keyword.get(init_arg, :replenish_interval, interval)

      if Enum.any?([token_count, interval, replenish_count, replenish_interval], &(&1 <= 0)) do
        raise ArgumentError, "Token counts and intervals must be positive integers"
      end

      with_log_metadata module: __MODULE__ do
        Logger.info(
          "Rate limiting ArchivesSpace requests to #{token_count} requests per #{interval}ms, replenishing #{replenish_count} tokens every #{replenish_interval}ms"
        )
      end

      state = %{
        max_tokens: token_count,
        replenish: {replenish_count, replenish_interval},
        tokens: token_count,
        queue: []
      }

      # Schedule token replenishment
      Process.send_after(self(), :replenish, interval)
      {:ok, state}
    end

    def handle_cast({action, work_id}, state) do
      if state.tokens > 0 do
        # Process the request immediately
        process_sync_action(action, work_id)
        {:noreply, %{state | tokens: state.tokens - 1}}
      else
        # Enqueue the request for later processing
        {:noreply, %{state | queue: state.queue ++ [{action, work_id}]}}
      end
    end

    def handle_info(:replenish, state) do
      {replenish_count, replenish_interval} = state.replenish

      state =
        if state.tokens < state.max_tokens do
          %{state | tokens: min(state.tokens + replenish_count, state.max_tokens)}
        else
          state
        end
        |> process_queue()

      # Reschedule the next replenishment
      Process.send_after(self(), :replenish, replenish_interval)
      {:noreply, state}
    end

    defp process_queue(state) do
      {to_process, remaining_queue} = Enum.split(state.queue, state.tokens)
      Enum.each(to_process, fn {action, work_id} -> process_sync_action(action, work_id) end)
      new_tokens = state.tokens - length(to_process)

      if new_tokens == 0 && not Enum.empty?(remaining_queue) do
        Logger.warning(
          "ArchivesSpace request rate limit reached. Queueing request for later processing."
        )
      end

      %{state | tokens: new_tokens, queue: remaining_queue}
    end

    defp process_sync_action(:sync_work, work_id) do
      with_log_metadata module: __MODULE__, id: work_id do
        Sync.sync_work(work_id)
      end
    end

    defp process_sync_action(:remove_work, work_id) do
      with_log_metadata module: __MODULE__, id: work_id do
        Sync.remove_work(work_id)
      end
    end
  end

  alias Meadow.Config

  use WalEx.Event, name: Meadow

  @synced_descriptive_fields ~w(title description abstract subject)

  on_event(:works, %{}, [{__MODULE__, :handle_event}], & &1)

  def handle_event(%{type: :update, new_record: record, changes: changes}) do
    if Config.archives_space_enabled?() and synced_fields_changed?(changes) do
      Processor.sync_work(record.id)
    end
  end

  def handle_event(%{type: :delete, old_record: record}) do
    if Config.archives_space_enabled?() do
      Processor.remove_work(record.id)
    end
  end

  def handle_event(_), do: :noop

  defp synced_fields_changed?(changes) when is_map(changes) do
    Map.has_key?(changes, :published) or
      Map.has_key?(changes, :visibility) or
      descriptive_metadata_changed?(changes)
  end

  defp descriptive_metadata_changed?(%{
         descriptive_metadata: %{old_value: old, new_value: new}
       })
       when is_map(old) and is_map(new) do
    Map.take(old, @synced_descriptive_fields) != Map.take(new, @synced_descriptive_fields)
  end

  defp descriptive_metadata_changed?(_), do: false
end
