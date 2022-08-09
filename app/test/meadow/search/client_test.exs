defmodule Meadow.Search.ClientTest do
  use Meadow.DataCase
  use Meadow.IndexCase

  import ExUnit.CaptureLog
  import Meadow.IndexCase

  alias Meadow.Config
  alias Meadow.Data.Indexer
  alias Meadow.Data.Schemas.Work
  alias Meadow.Search.Client

  setup do
    data = indexable_data()
    Indexer.synchronize_index()

    {:ok, data}
  end

  test "delete_by_query/3", %{count: count} do
    target = Config.v1_index()
    query = %{query: %{match_all: %{}}}

    assert capture_log(fn ->
             assert indexed_doc_count(target) == count
             assert {:ok, ^count} = Client.delete_by_query(target, query)
           end) =~ "Deleting #{count} documents from #{target}"
  end

  test "indexed_doc_count/1" do
    assert {:ok, 16} = Client.indexed_doc_count(Config.v1_index())
    assert {:ok, 0} = Client.indexed_doc_count(Config.v2_index("Work"))
    assert {:error, reason} = Client.indexed_doc_count("BAD_INDEX")
    assert reason =~ "BAD_INDEX"
  end

  test "latest_v2_indexed_time/1" do
    assert {:ok, "1970-01-01"} = Client.latest_v2_indexed_time("Collection")

    now = NaiveDateTime.utc_now()

    data =
      %{
        adminEmail: "test@example.com",
        createDate: now,
        findingAidUrl: "test",
        modifiedDate: now,
        representativeImage: "test",
        model: "test",
        visibility: %{label: "test"},
        title: "Test",
        indexed_at: now
      }
      |> Jason.encode!()

    with cluster <- Config.elasticsearch_url(),
         url <-
           Elastix.HTTP.prepare_url(cluster, [Config.v2_index("Collection"), "_doc"]) do
      Elastix.HTTP.post(url, data, [{"Content-Type", "application/json"}])
    end

    :timer.sleep(1000)

    with {:ok, latest_indexed_time} <- Client.latest_v2_indexed_time("Collection") do
      assert :eq = NaiveDateTime.compare(now, NaiveDateTime.from_iso8601!(latest_indexed_time))
    end
  end

  test "reindex/2" do
    assert {:ok, 16} = Client.indexed_doc_count(Config.v1_index())
    assert {:ok, 0} = Client.indexed_doc_count(Config.v2_index("Work"))

    {:ok, task} = Client.reindex("Work", "1970-01-01")

    with {:ok, task_created_count} <- Client.task_created_count(task),
         {:ok, search_hits} <- Client.search(Config.v2_index("Work"), %{query: %{match_all: %{}}}) do
      assert task_created_count == length(search_hits)
    end
  end

  test "search/3" do
    with target <- Config.v1_index(),
         query <- %{query: %{match_all: %{}}} do
      assert {:ok, _docs} = Client.search(target, query)
    end

    with target <- [Config.v1_index(), Config.v2_index(Work)],
         query <- %{query: %{match_all: %{}}} do
      assert {:ok, _docs} = Client.search(target, query)
    end

    assert({:error, _reason} = Client.search("BAD_INDEX", %{query: %{}}))
  end

  test "task_completed?/1" do
    assert Client.task_completed?(nil)
    {:ok, task} = Client.reindex("Work", "1970-01-01")
    refute Client.task_completed?(task)
    :timer.sleep(1000)
    assert Client.task_completed?(task)
  end
end
