defmodule Meadow.Data.ReindexerTest do
  use Meadow.DataCase
  use Meadow.IndexCase

  alias Meadow.Data.{Indexer, Reindexer}
  alias Meadow.Data.Schemas.{Collection, FileSet, Work}
  alias Meadow.Repo

  import Assertions
  import ExUnit.CaptureLog

  @timeout 10_000

  setup do
    data = indexable_data()
    Indexer.synchronize_index()

    {:ok, data}
  end

  describe "synchronize/1" do
    test "first pass" do
      log =
        capture_log(fn ->
          for {_state, task_id} <-
                Reindexer.synchronize(%{Collection: nil, FileSet: nil, Work: nil}) do
            refute is_nil(task_id)
          end
        end)

      assert log |> String.contains?("Documents newer than 1970-01-01")

      assert_async timeout: @timeout, sleep_interval: 250 do
        log =
          capture_log(fn -> Reindexer.synchronize(%{Collection: nil, FileSet: nil, Work: nil}) end)

        refute log |> String.contains?("Documents newer than 1970-01-01")
        assert all_synchronized?([Work, FileSet, Collection])
      end
    end

    test "add documents", data do
      reindexer_state = Reindexer.synchronize(%{Collection: nil, FileSet: nil, Work: nil})

      work_with_file_sets_fixture(3, %{collection_id: data.collection.id})
      log = capture_log(fn -> Indexer.synchronize_index() end)
      assert log |> String.contains?("Index updates: +3 ~0 -0")
      assert log |> String.contains?("Index updates: +1 ~0 -0")

      assert_async timeout: @timeout, sleep_interval: 250 do
        Reindexer.synchronize(reindexer_state)
        assert all_synchronized?([Work, FileSet, Collection])
      end
    end

    test "delete documents", data do
      Reindexer.synchronize(%{Collection: nil, FileSet: nil, Work: nil})

      assert_async timeout: @timeout, sleep_interval: 150 do
        assert all_synchronized?([Work, FileSet, Collection])
      end

      data.works
      |> Enum.take(2)
      |> Enum.each(&Repo.delete/1)

      log = capture_log(fn -> Indexer.synchronize_index() end)
      assert Regex.scan(~r/Index updates: \+0 ~0 -12/, log) |> List.flatten() |> length() == 2

      assert_async timeout: @timeout, sleep_interval: 250 do
        assert all_synchronized?([Work, FileSet, Collection])
      end
    end
  end
end
