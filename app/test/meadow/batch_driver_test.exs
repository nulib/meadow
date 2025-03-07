defmodule Meadow.BatchDriverTest do
  use Meadow.DataCase, shared: true
  use Meadow.IndexCase

  import Assertions
  import ExUnit.CaptureLog

  alias Meadow.{BatchDriver, Batches}
  alias Meadow.Data.{Indexer, Works}

  @args [interval: 100]

  setup do
    worker = start_supervised!({BatchDriver, @args})
    work_fixture()
    work_fixture()
    work_fixture()
    Indexer.reindex_all()
    {:ok, %{worker: worker}}
  end

  test "drive_batch/1" do
    assert Batches.list_batches() |> length() == 0
    assert Works.list_works() |> length() == 3

    logged =
      capture_log(fn ->
        assert Logger.enabled?(self())

        query = ~s'{"query":{"match_all":{}}}'
        user = "user123"
        type = "update"

        replace = %{
          descriptive_metadata: %{
            alternate_title: ["First", "Second"]
          }
        }

        attrs = %{
          query: query,
          type: type,
          user: user,
          replace: Jason.encode!(replace)
        }

        {:ok, batch} = Batches.create_batch(attrs)

        assert_async(timeout: 3000, sleep_time: 150) do
          assert Batches.list_batches() |> length() == 1
          batch = Batches.get_batch!(batch.id)
          assert batch.status == "complete"
          assert batch.active == false
          assert batch.works_updated == 3
        end
      end)

    Works.list_works()
    |> Enum.each(fn work ->
      assert work.descriptive_metadata.alternate_title |> length() == 2
      assert work.descriptive_metadata.alternate_title == ["First", "Second"]
    end)

    assert logged |> String.contains?("Starting batch")
  end
end
