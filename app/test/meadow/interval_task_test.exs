defmodule Meadow.IntervalTaskTest do
  use ExUnit.Case

  defmodule IntervalSender do
    use Meadow.IntervalTask, default_interval: 500, function: :ping

    @impl Meadow.IntervalTask
    def initial_state(args) do
      %{receiver: Keyword.get(args, :receiver)}
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
    start_supervised!({IntervalSender, interval: @test_interval, receiver: self()})
    :ok
  end

  test ":interval_task" do
    :timer.sleep(@test_interval * 4)
    assert_received(%{tick: 1})
    assert_received(%{tick: 2})
    assert_received(%{tick: 3})
    refute_received(%{tick: 7})
  end

  test "pause!/1" do
    Meadow.IntervalTask.pause!(IntervalSender)
    :timer.sleep(@test_interval * 4)
    refute_received(%{tick: 2})
  end

  test "resume!/1" do
    Meadow.IntervalTask.pause!(IntervalSender)
    :timer.sleep(@test_interval * 2)
    refute_received(%{tick: 2})

    Meadow.IntervalTask.resume!(IntervalSender)
    :timer.sleep(@test_interval * 3)
    assert_received(%{tick: 1})
    assert_received(%{tick: 2})
  end
end
