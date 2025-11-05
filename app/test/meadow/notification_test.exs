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
end
