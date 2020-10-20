defmodule Meadow.IntervalTask do
  @moduledoc """
  Perform periodic tasks. *Note*: The given interval is the delay between the _end_ of one
  call and the start of the next, not a reliable clock-tick.

  Example:

  ```
  defmodule MyRecurringTask do
    use Meadow.IntervalTask default_interval: 10_000, function: :do_the_thing

    def do_the_thing(state) do
      # Do the periodic task here
      {:noreply, state}
    end
  end
  ```

  Add to the list of children in `lib/meadow/application/children.ex`:
  ```
  def specs(:dev) do
    [
      MyRecurringTask
    ]
  end
  ```

  or

  ```
  def specs(:dev) do
    [
      {MyRecurringTask, interval: 1_000}
    ]
  end
  ```
  """

  @callback initial_state(args :: any()) :: map()

  defmacro __using__(use_opts) do
    quote location: :keep,
          bind_quoted: [
            default_interval: Keyword.get(use_opts, :default_interval, 1_000),
            function: Keyword.get(use_opts, :function, :trigger)
          ] do
      use GenServer
      require Logger

      @behaviour Meadow.IntervalTask

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]}
        }
      end

      def start_link(args \\ []) do
        GenServer.start_link(__MODULE__, args, name: __MODULE__)
      end

      def init(args) do
        interval = Keyword.get(args, :interval, unquote(default_interval))

        Logger.info(
          "IntervalTask: Invoking #{__MODULE__}.#{unquote(function)} every #{interval}ms"
        )

        state =
          initial_state(args)
          |> Map.merge(%{interval: interval, status: :running})

        Process.send_after(self(), :interval_task, state.interval)
        {:ok, state}
      end

      @impl Meadow.IntervalTask
      def initial_state(_args), do: %{}
      defoverridable initial_state: 1

      def handle_info(:pause, state), do: {:noreply, Map.put(state, :status, :paused)}

      def handle_info(:resume, %{status: :paused} = state) do
        Process.send_after(self(), :interval_task, state.interval)
        {:noreply, Map.put(state, :status, :running)}
      end

      def handle_info(:resume, state), do: {:noreply, state}

      def handle_info({:ssl_closed, _msg}, state), do: {:noreply, state}

      def handle_info(:interval_task, state) do
        with {response, new_state} <- apply(__MODULE__, unquote(function), [state]) do
          if new_state.status == :running do
            Process.send_after(self(), :interval_task, new_state.interval)
          end

          {response, new_state}
        end
      end
    end
  end

  def pause!(module) do
    case Process.whereis(module) do
      nil -> {:noreply, nil}
      pid -> send(pid, :pause)
    end
  end

  def resume!(module) do
    case Process.whereis(module) do
      nil -> {:noreply, nil}
      pid -> send(pid, :resume)
    end
  end
end
