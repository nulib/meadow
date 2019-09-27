defmodule Meadow.Ingest.Pipeline.ActionTest do
  use Meadow.PipelineCase

  doctest Meadow.Ingest.Pipeline.Action

  describe "action" do
    @tag pipeline: ["ProcessB", ProcessA: [ok: "ProcessB"]]
    test "simple pipeline", context do
      defmodule ProcessA do
        alias Meadow.Ingest.Pipeline.Action
        use Action

        def process(data) do
          {:ok, data |> Map.put("a", "received")}
        end
      end

      defmodule ProcessB do
        alias Meadow.Ingest.Pipeline.Action
        use Action

        def process(data) do
          {:error, data |> Map.put("b", "received")}
        end
      end

      start_supervised({ProcessA, receive_interval: 100})
      start_supervised({ProcessB, receive_interval: 100})
      ProcessA.send_message(%{started: "now"})

      assert_receive({:ok, %{"started" => "now", "a" => "received"}}, 5000)
      assert_receive({:error, %{"started" => "now", "a" => "received", "b" => "received"}}, 5000)
    end
  end
end
