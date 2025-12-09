defmodule Meadow.NotificationTest do
  use ExUnit.Case, async: true
  alias Meadow.Notification

  describe "register/1, registered/0, unregister/1" do
    setup do
      pid = self()
      on_exit(fn -> Notification.unregister(pid) end)
      {:ok, %{pid: pid}}
    end

    test "registers and unregisters processes", %{pid: pid} do
      assert :ok = Notification.register(pid)
      assert Notification.registered() |> Enum.member?(pid)
      assert :ok = Notification.unregister(pid)
      refute Notification.registered() |> Enum.member?(pid)
    end

    test "handles double registration", %{pid: pid} do
      assert :ok = Notification.register(pid)
      assert {:error, :already_registered} = Notification.register(pid)
      assert Notification.registered() |> Enum.member?(pid)
    end

    test "handles unregistering unregistered process", %{pid: pid} do
      assert {:error, :not_registered} = Notification.unregister(pid)
    end
  end

  describe "publish/2" do
    setup do
      pid = self()
      on_exit(fn -> Notification.unregister(pid) end)
      {:ok, %{pid: pid}}
    end

    test "publishes to registered processes", %{pid: pid} do
      Notification.register(pid)
      assert :ok = Notification.publish(:test_event, %{data: "test_data"})
      assert_receive {:notify, :test_event, %{data: "test_data"}}, 250
    end

    test "does not publish to unregistered processes", %{pid: pid} do
      refute Notification.registered() |> Enum.member?(pid)
      assert :ok = Notification.publish(:test_event, %{data: "test_data"})

      refute_receive {:notify, :test_event, %{data: "test_data"}}, 250
    end
  end

  describe "heartbeat" do
    setup do
      pid = self()
      on_exit(fn -> Notification.unregister(pid) end)
      {:ok, %{pid: pid}}
    end

    test "sends periodic heartbeat notifications", %{pid: pid} do
      Notification.register(pid)

      data = %{
        "test1" => {:message1, 75},
        "test2" => {:message2, 100}
      }

      pids =
        for {info, {message, interval}} <- data do
          {:ok, heartbeat_pid} = Meadow.Notification.Heartbeat.start(message, %{test: info}, interval)
          heartbeat_pid
        end

      # Collect messages with timestamps as they arrive
      # We expect 3 of each message type over ~300ms
      received =
        for _ <- 1..6 do
          receive do
            {:notify, message, %{test: info}} ->
              {message, info, System.monotonic_time(:millisecond)}
          after
            1000 -> flunk("Timeout waiting for heartbeat message")
          end
        end
        |> Enum.group_by(fn {_, info, _} -> info end)

      for {info, {message, expected_interval}} <- data do
        messages = Map.get(received, info, [])
        assert length(messages) == 3, "Expected 3 messages for info #{inspect(info)}"
        timestamps = Enum.map(messages, fn {_, _, ts} -> ts end)
        intervals =
          timestamps
          |> Enum.chunk_every(2, 1, :discard)
          |> Enum.map(fn [t1, t2] -> t2 - t1 end)

        for interval <- intervals do
          assert_in_delta interval, expected_interval, 10,
            "Expected ~#{expected_interval}ms interval for #{inspect(message)} with info #{inspect(info)}, got #{interval}ms"
        end
      end

      for pid <- pids do
        assert :ok = Meadow.Notification.Heartbeat.stop(pid)
      end
    end
  end
end
