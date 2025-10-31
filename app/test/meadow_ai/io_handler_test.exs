defmodule MeadowAI.IOHandlerTest do
  use ExUnit.Case

  alias MeadowAI.IOHandler
  import ExUnit.CaptureLog

  describe "MeadowAI.IOHandler" do
    setup do
      old_level = Logger.level()
      Logger.configure(level: :debug)
      config = MeadowAI.Config.get(:metrics_log)
      {:ok, pid} = IOHandler.open()

      on_exit(fn ->
        IOHandler.close(pid)
        Logger.configure(level: old_level)
        CloudwatchLogs.delete_log_stream(config[:group], config[:stream]) |> ExAws.request()
      end)

      %{io: pid, config: config}
    end

    test "processes regular log messages", %{io: io} do
      log =
        capture_log(fn ->
          IO.write(io, ~s({"type": "debug", "message": "this is a debug message"}\n))
          IO.write(io, ~s({"type": "info", "message": "this is an info message"}\n))
          IO.write(io, ~s({"type": "warning", "message": "this is a warning message"}\n))
          IO.write(io, ~s({"type": "error", "message": "this is an error message"}\n))
        end)

      assert String.contains?(log, "[debug] this is a debug message")
      assert String.contains?(log, "[info] this is an info message")
      assert String.contains?(log, "[warning] this is a warning message")
      assert String.contains?(log, "[error] this is an error message")
    end

    test "logs text messages", %{io: io} do
      log =
        capture_log(fn ->
          IO.write(io, ~s({"type": "text", "message": "This is a text message."}\n))
        end)

      assert String.contains?(log, "[notice] This is a text message.")
    end

    test "logs text tool result", %{io: io} do
      log =
        capture_log(fn ->
          IO.write(
            io,
            ~s({"type": "tool_result", "message": "This is the tool output."}\n)
          )
        end)

      assert String.contains?(log, "[info] Tool Result:\nThis is the tool output.")
    end

    test "logs JSON tool result", %{io: io} do
      message =
        %{
          message:
            "{\"plan\":{\"completed_at\":null,\"error\":null,\"id\":\"3c5584a4-5804-4740-9731-4eeeae7f354e\",\"inserted_at\":\"2025-10-30T17:05:45.065590Z\",\"notes\":null,\"prompt\":\"Can you add an alternate title of \\\"tool calling test\\\"\",\"query\":\"id:(84e7c313-d052-4245-856c-71a007b2fd12)\",\"status\":\"proposed\",\"updated_at\":\"2025-10-30T17:06:27.390802Z\",\"user\":null}}",
          type: "tool_result"
        }
        |> Jason.encode!()

      log =
        capture_log(fn -> IO.write(io, message <> "\n") end)

      assert String.contains?(log, "[info] Tool Result:\n%{")

      assert String.contains?(
               log,
               ~s("prompt" => "Can you add an alternate title of \\"tool calling test\\"")
             )
    end

    test "logs usage metrics", %{io: io, config: metrics_config} do
      usage = %{
        "cost" => 0.09499395000000001,
        "tokens" => %{
          "cache_creation" => %{
            "ephemeral_1h_input_tokens" => 0,
            "ephemeral_5m_input_tokens" => 0
          },
          "cache_creation_input_tokens" => 10_833,
          "cache_read_input_tokens" => 10_040,
          "input_tokens" => 10,
          "output_tokens" => 765,
          "server_tool_use" => %{"web_search_requests" => 0},
          "service_tier" => "standard"
        }
      }

      IO.write(io, Jason.encode!(%{"type" => "usage", "message" => usage}) <> "\n")

      assert %{"events" => [event | _]} =
               CloudwatchLogs.get_log_events(metrics_config[:group], metrics_config[:stream])
               |> ExAws.request!()

      assert {:ok, ^usage} = Jason.decode(event["message"])
    end

    test "logs raw messages", %{io: io} do
      raw_message = "This is a raw message."

      log =
        capture_log(fn ->
          IO.write(io, ~s({"type": "raw_message", "message": "#{raw_message}"}\n))
        end)

      assert String.contains?(log, ~s([info] Raw Message:\n"#{raw_message}"))
    end

    test "logs unknown message types", %{io: io} do
      unknown_message = "This is an unknown message."

      log =
        capture_log(fn ->
          IO.write(io, ~s({"type": "unknown_type", "message": "#{unknown_message}"}\n))
        end)

      assert String.contains?(
               log,
               ~s([info] Received Message of type unknown_type:\n"#{unknown_message}")
             )
    end
  end
end
