defmodule Meadow.Utils.LambdaTest do
  use ExUnit.Case
  alias Meadow.Utils.Lambda
  import ExUnit.CaptureLog
  require Logger

  @port_regex ~r/(?<port>#Port<\d+.\d+>)/

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
    test "spawns on first run", %{config: config} do
      log =
        capture_log(fn ->
          assert Lambda.invoke(config, %{boolean: true, number: 123, type: "map"}) ==
                   {:ok,
                    %{
                      "type" => "complex",
                      "result" => %{"boolean" => true, "number" => 123, "type" => "map"}
                    }}
        end)

      assert log |> String.match?(~r/\[debug\] Spawned .+ in new port #Port<\d+.\d+>/)
      assert log |> String.contains?("[info]  This is a log message with level `log`")
      assert log |> String.contains?("[warn]  This is a log message with level `warn`")
      assert log |> String.contains?("[error] This is a log message with level `error`")
      assert log |> String.contains?("[info]  This is a log message with level `info`")
      assert log |> String.contains?("[debug] This is a log message with level `debug`")
      refute log |> String.contains?("[debug] ping")

      assert log
             |> String.contains?(
               "[warn]  Unknown message received: This is an unknown message type"
             )
    end

    test "reuses on subsequent run", %{config: config} do
      log =
        capture_log(fn ->
          Lambda.invoke(config, %{boolean: true, number: 123, type: "map"})
        end)

      assert [[msg]] = Regex.scan(~r/\[debug\] Spawned .+ in new port #Port<\d+.\d+>/, log)
      assert %{"port" => port} = Regex.named_captures(@port_regex, msg)

      log =
        capture_log(fn ->
          Lambda.invoke(config, %{boolean: true, number: 123, type: "map"})
        end)

      assert [[msg]] = Regex.scan(~r/\[debug\] Using port #Port<\d+.\d+>/, log)
      assert Regex.named_captures(@port_regex, msg) == %{"port" => port}
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

    test "timeout", %{config: config} do
      assert capture_log(fn ->
               assert Lambda.invoke(config, %{test: "sleep", duration: 250}, 50) ==
                        {:error, "Timeout"}
             end) =~ ~r/No response after 50ms/

      log =
        capture_log(fn ->
          Lambda.invoke(config, %{boolean: true, number: 123, type: "map"})
        end)

      assert [[msg]] = Regex.scan(~r/\[debug\] Spawned .+ in new port #Port<\d+.\d+>/, log)
      assert %{"port" => _} = Regex.named_captures(@port_regex, msg)
    end
  end

  describe "close/1" do
    test "does nothing if port is not active", %{config: config} do
      assert Lambda.close(config) == :noop
    end

    test "closes an active port", %{config: config} do
      log =
        capture_log(fn ->
          Lambda.invoke(config, %{boolean: true, number: 123, type: "map"})
        end)

      assert [[msg]] = Regex.scan(~r/\[debug\] Spawned .+ in new port #Port<\d+.\d+>/, log)
      assert %{"port" => old_port} = Regex.named_captures(@port_regex, msg)

      log =
        capture_log(fn ->
          assert Lambda.close(config) == :ok
        end)

      assert [[msg]] = Regex.scan(~r/\[debug\] Closing port #Port<\d+.\d+>/, log)
      assert Regex.named_captures(@port_regex, msg) == %{"port" => old_port}

      log =
        capture_log(fn ->
          Lambda.invoke(config, %{boolean: true, number: 123, type: "map"})
        end)

      assert [[msg]] = Regex.scan(~r/\[debug\] Spawned .+ in new port #Port<\d+.\d+>/, log)
      assert %{"port" => new_port} = Regex.named_captures(@port_regex, msg)
      assert new_port != old_port
    end
  end
end
