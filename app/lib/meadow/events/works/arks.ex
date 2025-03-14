defmodule Meadow.Events.Works.Arks do
  @moduledoc """
  Handles events related to ARKs.
  """

  defmodule Processor do
    @moduledoc """
    Rate-limited processor for ARK-related events.

    Supports the following init arguments:
    * `:token_count` - the maximum number of ARK requests to process in a given interval (default: 100)
    * `:interval` - the interval in milliseconds over which to process the maximum number of ARK requests (default: 1_000)
    * `:replenish_count` - the number of tokens added back to the pool per replenishment (default: `:token_count`)
    * `:replenish_interval` - the replenishment interval in milliseconds (default: `:interval`)
    """
    use GenServer

    alias Meadow.Arks
    alias Meadow.Data.Works

    use Meadow.Utils.Logging

    require Logger

    @token_count 100
    @interval 1_000

    # Client API
    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, opts, name: __MODULE__)
    end

    def mint_ark(work_id), do: GenServer.cast(__MODULE__, {:mint_ark, work_id})
    def update_ark(work_id), do: GenServer.cast(__MODULE__, {:update_ark, work_id})
    def delete_ark(work_id), do: GenServer.cast(__MODULE__, {:delete_ark, work_id})

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
          "Rate limiting Ark requests to #{token_count} requests per #{interval}ms, replenishing #{replenish_count} tokens every #{replenish_interval}ms"
        )
      end

      state = %{
        max_tokens: token_count,
        rate: {token_count, interval},
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
        process_ark_action(action, work_id)
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
          new_tokens = min(state.tokens + replenish_count, state.max_tokens)
          # Replenish tokens
          %{state | tokens: new_tokens}
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
      Enum.each(to_process, fn {action, work_id} -> process_ark_action(action, work_id) end)
      new_tokens = state.tokens - length(to_process)

      if new_tokens == 0 && not Enum.empty?(state.queue) do
        Logger.warning("Ark request rate limit reached. Queueing request for later processing.")
      end

      %{state | tokens: new_tokens, queue: remaining_queue}
    end

    defp process_ark_action(:mint_ark, work_id) do
      with_log_metadata module: __MODULE__, id: work_id do
        Works.get_work(work_id) |> Arks.mint_ark()
      end
    end

    defp process_ark_action(:update_ark, work_id) do
      with_log_metadata module: __MODULE__, id: work_id do
        case Works.get_work!(work_id) do
          nil -> :noop
          work -> update_ark_metadata(work)
        end
      end
    end

    defp process_ark_action(:delete_ark, work_id) do
      with_log_metadata module: __MODULE__, id: work_id do
        Arks.work_deleted(work_id)
      end
    end

    defp update_ark_metadata(work) do
      Logger.info(
        "Updating ARK metadata for work: #{work.id}, with ark: #{work.descriptive_metadata.ark}"
      )

      case Arks.update_ark_metadata(work) do
        :noop ->
          :noop

        {:ok, _result} ->
          :noop

        {:error, error_message} ->
          Logger.error(
            "Error updating ARK metadata for work: #{work.id}, with ark: #{work.descriptive_metadata.ark}. #{error_message}"
          )
      end
    end
  end

  use WalEx.Event, name: Meadow

  require Logger

  on_event(:works, %{}, [{__MODULE__, :handle_event}], & &1)

  def handle_event(%{type: :insert, new_record: record}) do
    Processor.mint_ark(record.id)
  end

  def handle_event(%{type: :update, new_record: record, changes: changes}) do
    unless ark_changed(changes) do
      Processor.update_ark(record.id)
    end
  rescue
    Ecto.NoResultsError -> :noop
  end

  def handle_event(%{type: :delete, old_record: record}) do
    Processor.delete_ark(record.id)
  end

  defp ark_changed(%{published: _}), do: false
  defp ark_changed(%{visibility: _}), do: false

  defp ark_changed(%{
         descriptive_metadata: %{
           old_value: %{"ark" => old_ark},
           new_value: %{"ark" => new_ark}
         }
       }) do
    old_ark != new_ark
  end

  defp ark_changed(_), do: false
end
