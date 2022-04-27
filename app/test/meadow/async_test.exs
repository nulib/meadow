defmodule Meadow.AsyncTest do
  use ExUnit.Case

  describe "sync (test) mode" do
    test "runs synchronously" do
      assert {:sync, _} =
               Meadow.Async.run_once("test:123", fn ->
                 :synchronous_test_result
               end)

      assert_received({"test:123", :synchronous_test_result})
    end
  end

  describe "async mode" do
    test "runs asynchronously" do
      assert {:ok, _} =
               Meadow.Async.run_once(
                 "test:123",
                 fn ->
                   :asynchronous_test_result
                 end,
                 :dev
               )

      assert_receive({"test:123", :asynchronous_test_result}, 1000)
    end

    test "detects a running process" do
      assert {:ok, pid} =
               Meadow.Async.run_once(
                 "test:123",
                 fn ->
                   assert {:running, _} =
                            Meadow.Async.run_once("test:123", fn -> :result end, :dev)
                 end,
                 :dev
               )

      assert_receive({"test:123", {:running, ^pid}}, 1000)
    end
  end
end
