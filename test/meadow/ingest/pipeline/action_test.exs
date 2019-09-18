defmodule Meadow.Ingest.Pipeline.ActionTest do
  use Meadow.PipelineCase

  doctest Meadow.Ingest.Pipeline.Action
  import Meadow.PipelineCase

  describe "action" do
    @tag pipeline: ["process-a", "process-b": [ok: "process-a"]]
    test "simple pipeline", context do
      defmodule ProcessA do
        alias Meadow.Ingest.Pipeline.Action
        use Action

        def start_link(_) do
          Action.start_link(__MODULE__, queue_name: "process-a", receive_interval: 100)
        end

        def process(data) do
          {:ok, data |> Map.put("a", "received")}
        end
      end

      defmodule ProcessB do
        alias Meadow.Ingest.Pipeline.Action
        use Action

        def start_link(_) do
          Action.start_link(__MODULE__, queue_name: "process-b", receive_interval: 100)
        end

        def process(data) do
          {:error, data |> Map.put("b", "received")}
        end
      end

      start_supervised(ProcessA)
      start_supervised(ProcessB)
      send_message("process-a", "{}")

      assert_receive({:ok, %{"a" => "received"}}, 5000)
      assert_receive({:error, %{"a" => "received", "b" => "received"}}, 5000)
    end
  end
end
