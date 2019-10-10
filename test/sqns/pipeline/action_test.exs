defmodule SQNS.Pipeline.ActionTest do
  use SQNS.PipelineCase

  doctest SQNS.Pipeline.Action

  @timeout 2000

  describe "action" do
    @tag pipeline: [
           :ProcessA,
           ProcessB: [ProcessA: [status: :ok, user_data: :xyz]],
           ProcessC: [ProcessA: [user_data: :bleh]]
         ]
    test "simple pipeline", context do
      defmodule ProcessA do
        alias SQNS.Pipeline.Action
        use Action

        def process(data, _) do
          {:ok, data |> Map.put(:a, "received")}
        end
      end

      defmodule ProcessB do
        alias SQNS.Pipeline.Action
        use Action

        def process(data, _) do
          {:error, data |> Map.put(:b, "received")}
        end
      end

      defmodule ProcessC do
        alias SQNS.Pipeline.Action
        use Action

        def process(data, _) do
          {:error, data |> Map.put(:c, "received")}
        end
      end

      start_supervised({ProcessA, receive_interval: 10})
      start_supervised({ProcessB, receive_interval: 10})
      time = System.monotonic_time(:millisecond)
      ProcessA.send_message(%{started: time}, %{user_data: "xyz"})

      assert_receive(
        {%{started: ^time, a: "received"}, %{status: "ok", user_data: xyz}},
        @timeout
      )

      assert_receive(
        {%{started: ^time, a: "received", b: "received"},
         %{status: "error", user_data: "xyz"}},
        @timeout
      )

      refute_receive(
        {%{started: ^time, a: "received", c: "received"},
         %{status: "error", user_data: "bleh"}},
        @timeout
      )
    end
  end
end
