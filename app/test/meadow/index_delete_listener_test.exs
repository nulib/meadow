defmodule Meadow.IndexDeleteListenerTest do
  use Meadow.UnsandboxedDataCase, async: false
  use Meadow.IndexCase

  import Assertions

  alias Ecto.Adapters.SQL.Sandbox
  alias Meadow.Data.Indexer
  alias Meadow.Repo

  setup %{repo: repo} do
    pid = start_supervised!({Meadow.IndexDeleteListener, repo: repo})

    {:ok, %{pid: pid}}
  end

  @tag unboxed: true
  test "deleted" do
    Sandbox.unboxed_run(Repo, fn ->
      context = indexable_data()
      assert_all_empty()
      Indexer.synchronize_index()
      assert_doc_counts_match(context)
      context.works |> List.first() |> Repo.delete()

      expected = %{
        total_count: context.total_count - 3,
        work_count: context.work_count - 1,
        file_set_count: context.file_set_count - 2,
        collection_count: context.collection_count
      }

      assert_async(timeout: 10_000, sleep_time: 150) do
        assert_doc_counts_match(expected)
      end
    end)
  end
end
