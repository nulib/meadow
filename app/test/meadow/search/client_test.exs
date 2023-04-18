defmodule Meadow.Search.ClientTest do
  use Meadow.DataCase
  use Meadow.IndexCase

  import ExUnit.CaptureLog
  import Meadow.IndexCase

  alias Meadow.Data.Indexer
  alias Meadow.Data.Schemas.{Collection, Work}
  alias Meadow.Search.{Client, HTTP}
  alias Meadow.Search.Config, as: SearchConfig

  describe "with data" do
    setup do
      data = indexable_data()
      Indexer.synchronize_index()

      {:ok, data}
    end

    test "delete_by_query/2", %{work_count: count} do
      target = SearchConfig.alias_for(Work, 2)

      query = %{query: %{match_all: %{}}}

      assert capture_log(fn ->
               {:ok, ^count} = Client.indexed_doc_count(target)
               {:ok, ^count} = Client.delete_by_query(target, query)
             end) =~ "Deleting #{count} documents from #{target}"
    end

    test "indexed_doc_count/1", %{work_count: count} do
      assert {:ok, ^count} = Client.indexed_doc_count(SearchConfig.alias_for(Work, 2))
      assert {:error, reason} = Client.indexed_doc_count("BAD_INDEX")
      assert reason =~ "BAD_INDEX"
    end

    test "search/2" do
      with target <- SearchConfig.alias_for(Work, 2),
           query <- %{query: %{match_all: %{}}} do
        assert {:ok, _docs} = Client.search(target, query)
      end

      with target <- [SearchConfig.alias_for(Work, 2), SearchConfig.alias_for(Collection, 2)],
           query <- %{query: %{match_all: %{}}} do
        assert {:ok, _docs} = Client.search(target, query)
      end

      assert({:error, _reason} = Client.search("BAD_INDEX", %{query: %{}}))
    end
  end

  describe "hot_swap/3" do
    test "by schema/version" do
      with expected_prefix <- SearchConfig.alias_for(Work, 2) <> "-" do
        Client.hot_swap(Work, 2, fn index ->
          assert String.starts_with?(index, expected_prefix)
          :ok
        end)
      end
    end

    test "by index/settings" do
      with index_name <- SearchConfig.alias_for(Collection, 2) do
        Client.hot_swap(index_name, %{}, fn index ->
          assert String.starts_with?(index, "#{index_name}-")
          :ok
        end)
      end
    end

    test "handles error in indexing function" do
      log =
        capture_log(fn ->
          Client.hot_swap(Work, 2, fn index ->
            {:error, "Whoa, reindexing #{index} blew up"}
          end)
        end)

      assert log =~ ~r/Problem performing hot swap/
      assert log =~ ~r/Whoa, reindexing .+ blew up/
    end
  end

  test "most_recent/2" do
    assert {:ok, _} = Client.most_recent(Collection, 2)

    now = NaiveDateTime.utc_now()

    data = %{
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

    with alias <- SearchConfig.alias_for(Collection, 2) do
      HTTP.post([alias, "_doc"], data)
      Client.refresh(alias)
    end

    with {:ok, latest_indexed_time} <- Client.most_recent(Collection, 2) do
      assert :eq = NaiveDateTime.compare(now, latest_indexed_time)
    end
  end
end
