defmodule Meadow.Utils.LambdaTest do
  use ExUnit.Case
  alias Meadow.Utils.Lambda
  import ExUnit.CaptureLog
  require Logger

  describe "invoke/2" do
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

      assert_received msg = "Spawning " <> _
      assert msg =~ ~r/Spawning .+ in a new port/

      assert log |> String.contains?("[info]  This is a log message with level `log`")
      assert log |> String.contains?("[warn]  This is a log message with level `warn`")
      assert log |> String.contains?("[error] This is a log message with level `error`")
      assert log |> String.contains?("[info]  This is a log message with level `info`")

      assert log
             |> String.contains?(
               "[warn]  Unknown message received: This is an unknown message type"
             )
    end

    test "reuses on subsequent run", %{config: config} do
      Lambda.invoke(config, %{boolean: true, number: 123, type: "map"})
      assert_received msg = "Spawning " <> _
      assert msg =~ ~r/Spawning .+ in a new port/

      :c.flush()

      Lambda.invoke(config, %{boolean: true, number: 123, type: "map"})
      assert_received msg = "Using port " <> _
      assert msg =~ ~r/Using port #Port<\d+.\d+>/
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

      Lambda.invoke(config, %{boolean: true, number: 123, type: "map"})
      assert_received msg = "Spawning " <> _
      assert msg =~ ~r/Spawning .+ in a new port/
    end
  end
end
