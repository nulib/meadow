defmodule Meadow.BackgroundTaskTest do
  use ExUnit.Case

  defmodule IntervalSender do
    use Meadow.BackgroundTask, default_interval: 500, function: :ping

    @impl Meadow.BackgroundTask
    def before_init(args) do
      {:ok, %{receiver: Keyword.get(args, :receiver)}}
    end

    @impl Meadow.BackgroundTask
    def handle_notification(:notified, payload, state) do
      send(state.receiver, payload)
      {:noreply, state}
    end

    def ping(state) do
      state =
        state
        |> Map.put(:tick, Map.get(state, :tick, 0) + 1)

      send(state.receiver, state)
      {:noreply, state}
    end
  end

  @test_interval 50

  setup do
    {:ok,
     %{task: start_supervised!({IntervalSender, interval: @test_interval, receiver: self()})}}
  end

  test ":interval_task" do
    :timer.sleep(@test_interval * 4)
    assert_received(%{tick: 1})
    assert_received(%{tick: 2})
    assert_received(%{tick: 3})
    refute_received(%{tick: 7})
  end

  test "notification", %{task: task} do
    with content <- {:time, DateTime.utc_now()} do
      assert_receive(content, 250)
      send(task, {:notification, "foo", "bar", "notified", content})
    end
  end

  test "pause!/1", %{task: task} do
    with content <- {:time, DateTime.utc_now()} do
      Meadow.BackgroundTask.pause!(IntervalSender)
      :timer.sleep(@test_interval * 4)
      refute_received(%{tick: 2})

      refute_receive(content, 250)
      send(task, {:notification, "foo", "bar", "notified", content})
    end
  end

  test "resume!/1", %{task: task} do
    with content <- {:time, DateTime.utc_now()} do
      Meadow.BackgroundTask.pause!(IntervalSender)
      :timer.sleep(@test_interval * 2)
      refute_received(%{tick: 2})
      refute_receive(content, 250)
      send(task, {:notification, "foo", "bar", "notified", content})

      Meadow.BackgroundTask.resume!(IntervalSender)
      :timer.sleep(@test_interval * 3)
      assert_received(%{tick: 1})
      assert_received(%{tick: 2})
      assert_receive(content, 250)
      send(task, {:notification, "foo", "bar", "notified", content})
    end
  end
end
