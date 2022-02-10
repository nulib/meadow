defmodule Meadow.Utils.LambdaTest do
  use ExUnit.Case
  alias Meadow.Utils.Lambda
  import ExUnit.CaptureLog
  require Logger

  setup do
    old_level = Logger.level()
    Logger.configure(level: :debug)

    on_exit(fn ->
      Logger.configure(level: old_level)
    end)

    with script <- Path.expand("./test/fixtures/lambda/index") do
      {:ok, %{config: {:local, {script, "testHandler"}}}}
    end
  end

  describe "invoke/2" do
    test "receives the correct result and logs", %{config: config} do
      log =
        capture_log(fn ->
          assert Lambda.invoke(config, %{boolean: true, number: 123, type: "map"}) ==
                   {:ok,
                    %{
                      "type" => "complex",
                      "result" => %{"boolean" => true, "number" => 123, "type" => "map"}
                    }}
        end)

      assert log |> String.contains?("[info]  This is a log message with level `log`")
      assert log |> String.match?(~r"\[warn(ing)?\]\s+This is a log message with level `warn`")
      assert log |> String.contains?("[error] This is a log message with level `error`")
      assert log |> String.contains?("[info]  This is a log message with level `info`")
      assert log |> String.contains?("[debug] This is a log message with level `debug`")
      refute log |> String.contains?("[debug] ping")

      assert log
             |> String.match?(
               ~r"\[warn(ing)?\]\s+Unknown message received: This is an unknown message type"
             )
    end

    test "fatal error", %{config: config} do
      assert capture_log(fn ->
               assert Lambda.invoke(config, %{test: "die"}) ==
                        {:error, "Dying because the caller told me to"}
             end)
             |> String.contains?("[error] Dying because the caller told me to")
    end

    test "exit", %{config: config} do
      assert Lambda.invoke(config, %{test: "quit", status: 123}) == {:error, "exit_status: 123"}
    end

    test "long data", %{config: config} do
      assert {:ok, %{"type" => "long", "result" => result}} =
               Lambda.invoke(config, %{test: "long"})

      assert result == File.read!("test/fixtures/lambda/lipsum.txt")
    end

    test "null response", %{config: config} do
      assert {:ok, nil} == Lambda.invoke(config, %{test: "null"})
    end

    test "undefined response", %{config: config} do
      log =
        capture_log(fn ->
          assert {:ok, nil} == Lambda.invoke(config, %{test: "undef"})
        end)

      assert log |> String.match?(~r"\[warn(ing)?\]\s+Received undefined")
    end

    test "timeout", %{config: config} do
      assert capture_log(fn ->
               assert Lambda.invoke(config, %{test: "sleep", duration: 250}, 50) ==
                        {:error, "Timeout"}
             end) =~ ~r/No response after 50ms/

      assert Lambda.close(config) == :noop
      assert {:new, _port} = Lambda.init(config)
    end
  end

  describe "init/1" do
    test "does nothing for remote functions" do
      assert Lambda.init({:lambda, "remote-function"}) == :noop
    end

    test "initializes a port", %{config: config} do
      assert {:new, port} = Lambda.init(config)
      assert port |> is_port()
    end

    test "uses an existing port", %{config: config} do
      assert {:new, port} = Lambda.init(config)
      assert {:existing, ^port} = Lambda.init(config)
    end

    test "bad script" do
      assert capture_log(fn ->
               assert {:error, nil} =
                        Lambda.init({:local, {"path/to/nonexistent/script.js", "handler"}})
             end) =~ ~r"Failed to spawn path/to/nonexistent/script.js: No such file"
    end
  end

  describe "close/1" do
    test "does nothing if port is not active", %{config: config} do
      assert Lambda.close(config) == :noop
    end

    test "closes an active port", %{config: config} do
      assert {:new, old_port} = Lambda.init(config)
      assert Lambda.close(config) == :ok
      assert {:new, new_port} = Lambda.init(config)
      assert new_port != old_port
    end
  end
end
