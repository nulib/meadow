defmodule Meadow.BackgroundTask do
  @moduledoc """
  Perform periodic and/or database notification tasks.
  *Note*: For periodic tasks, the given interval is the delay between the _end_ of one call and
  the start of the next, not a reliable clock-tick.

  Example:

  ```
  defmodule MyRecurringTask do
    use Meadow.BackgroundTask, default_interval: 10_000, function: :do_the_thing

    def do_the_thing(state) do
      # Do the periodic task here
      {:noreply, state}
    end
  end

  defmodule MyDatabaseNotificationTask do
    use Meadow.BackgroundTask, periodic: false

    @impl true
    def before_init(args) do
      Meadow.Repo.listen("some_notification_topic")
      :ok
    end

    @impl true
    def handle_notification(:some_notification_topic, payload, state) do
      # Do something with the notification
      {:noreply, state}
    end
  end
  ```

  Note that a module can handle both periodic _and_ notification tasks:

  defmodule MyTask do
    use Meadow.BackgroundTask, function: :periodic_task

    @impl true
    def before_init(args) do
      Meadow.Repo.listen("database_notification")
      :ok
    end

    @impl true
    def handle_notification(:database_notification, payload, state) do
      # Do something with the notification
      {:noreply, state}
    end

    def periodic_task(state) do
      # Do the periodic task here
      {:noreply, state}
    end
  end

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

  @callback before_init(args :: any()) :: map()
  @callback handle_notification(topic :: atom(), payload :: any(), state :: map()) ::
              {:noreply, map()}

  defmacro __using__(use_opts) do
    quote location: :keep,
          bind_quoted: [
            periodic: Keyword.get(use_opts, :periodic, true),
            default_interval: Keyword.get(use_opts, :default_interval, 1_000),
            function: Keyword.get(use_opts, :function, :trigger)
          ] do
      use GenServer
      require Logger

      @behaviour Meadow.BackgroundTask

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
        state =
          case %{periodic: unquote(periodic)} do
            %{periodic: true} = initial_state ->
              interval = Keyword.get(args, :interval, unquote(default_interval))

              Logger.info(
                "BackgroundTask: Invoking #{__MODULE__}.#{unquote(function)} every #{interval}ms"
              )

              Map.put(initial_state, :interval, interval)

            initial_state ->
              Logger.info("BackgroundTask: Starting #{__MODULE__}")
              initial_state
          end
          |> Map.put(:status, :running)
          |> Map.merge(do_before_init(args))

        {:ok, schedule(state)}
      end

      defp do_before_init(args) do
        case before_init(args) do
          :ok -> %{}
          {:ok, state} -> state
        end
      end

      @impl Meadow.BackgroundTask
      def before_init(_args), do: :ok
      defoverridable before_init: 1

      @impl Meadow.BackgroundTask
      def handle_notification(_, _, state), do: {:noreply, state}
      defoverridable handle_notification: 3

      @impl GenServer
      def handle_info(:pause, state) do
        state = Map.put(state, :status, :paused)

        case Map.get(state, :timer_ref) do
          nil ->
            {:noreply, state}

          ref ->
            Process.cancel_timer(ref)
            {:noreply, Map.delete(state, :timer_ref)}
        end
      end

      @impl GenServer
      def handle_info(:resume, %{status: :paused} = state) do
        {:noreply, Map.put(state, :status, :running) |> schedule()}
      end

      @impl GenServer
      def handle_info(:resume, state), do: {:noreply, state}

      @impl GenServer
      def handle_info({:ssl_closed, _msg}, state), do: {:noreply, state}

      @impl GenServer
      def handle_info(:interval_task, state) do
        state = Map.delete(state, :timer_ref)

        with {response, new_state} <- apply(__MODULE__, unquote(function), [state]) do
          {response, schedule(new_state)}
        end
      end

      @impl GenServer
      def handle_info({:notification, _pid, _ref, _topic, _payload}, %{status: :paused} = state),
        do: {:noreply, state}

      @impl GenServer
      def handle_info({:notification, _pid, _ref, topic, payload}, state) do
        topic =
          cond do
            is_atom(topic) -> topic
            is_binary(topic) -> String.to_atom(topic)
            topic -> topic |> to_string() |> String.to_atom()
          end

        with {response, new_state} <- handle_notification(topic, payload, state) do
          {response, schedule(new_state)}
        end
      end

      defp schedule(%{periodic: false} = state), do: state
      defp schedule(%{status: :paused} = state), do: state

      defp schedule(state) do
        ref = Process.send_after(self(), :interval_task, state.interval)
        Map.put(state, :timer_ref, ref)
      end
    end
  end

  @doc """
  Pause the task implemented by the given module. Neither periodic nor notification
  tasks will fire while the process is paused.
  """
  def pause!(module) do
    case Process.whereis(module) do
      nil -> {:noreply, nil}
      pid -> send(pid, :pause)
    end
  end

  @doc """
  Resume a paused task.
  """
  def resume!(module) do
    case Process.whereis(module) do
      nil -> {:noreply, nil}
      pid -> send(pid, :resume)
    end
  end
end
