defmodule Meadow.Embeddings.WorkerTest do
  use Meadow.DataCase

  import ExUnit.CaptureLog

  alias Meadow.Embeddings
  alias Meadow.Embeddings.Model.Stub
  alias Meadow.Embeddings.Worker

  setup do
    start_supervised!(Stub)
    {:ok, work: work_fixture()}
  end

  describe "enqueue/1" do
    test "is a no-op when the worker is not running", %{work: work} do
      assert Worker.enqueue([work.id]) == :ok
      assert Worker.flush() == 0
    end

    test "embeds queued works once the interval has passed", %{work: work} do
      worker = start_supervised!({Worker, interval: 10})
      Worker.enqueue([work.id])
      assert %{timer: timer} = :sys.get_state(worker)
      assert is_reference(timer)

      send(worker, :process)
      assert %{pending: pending} = :sys.get_state(worker)
      assert pending == %{}
      assert Embeddings.get_work_embedding(work.id)
    end
  end

  describe "flush/0" do
    test "deduplicates queued works", %{work: work} do
      start_supervised!({Worker, interval: :never})
      Worker.enqueue([work.id, work.id])
      Worker.enqueue([work.id])

      assert Worker.flush() == 0
      assert length(Stub.prompts()) == 1
      assert Embeddings.get_work_embedding(work.id)
    end

    test "processes more works than fit in one batch" do
      start_supervised!({Worker, interval: :never, batch_size: 2})
      works = for _ <- 1..5, do: work_fixture()
      works |> Enum.map(& &1.id) |> Worker.enqueue()

      assert Worker.flush() == 0
      assert Enum.all?(works, &Embeddings.get_work_embedding(&1.id))
    end

    test "retries failed works, then gives up", %{work: work} do
      start_supervised!({Worker, interval: :never, max_attempts: 2})
      Stub.fail_with(:model_unavailable)
      Worker.enqueue([work.id])

      assert capture_log(fn -> assert Worker.flush() == 1 end) =~ "Failed to embed 1 works"
      assert capture_log(fn -> assert Worker.flush() == 0 end) =~ "Giving up on embedding"
      refute Embeddings.get_work_embedding(work.id)
    end

    test "recovers when the model comes back", %{work: work} do
      start_supervised!({Worker, interval: :never})
      Stub.fail_with(:model_unavailable)
      Worker.enqueue([work.id])
      capture_log(fn -> assert Worker.flush() == 1 end)

      Stub.fail_with(nil)
      assert Worker.flush() == 0
      assert Embeddings.get_work_embedding(work.id)
    end
  end
end
