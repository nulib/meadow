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

    test "doc/3 with schema and version", %{works: [work | _]} do
      # Test successful retrieval using schema/version
      assert {:ok, doc} = Client.doc(Work, 2, work.id)
      assert doc["id"] == work.id
      assert doc["accession_number"] == work.accession_number
    end

    test "doc/2 with target string", %{works: [work | _]} do
      target = SearchConfig.alias_for(Work, 2)

      # Test successful retrieval using target string
      assert {:ok, doc} = Client.doc(target, work.id)
      assert doc["id"] == work.id
      assert doc["accession_number"] == work.accession_number
    end

    test "doc/2 handles not found" do
      target = SearchConfig.alias_for(Work, 2)
      non_existent_id = Ecto.UUID.generate()

      assert {:error, :not_found} = Client.doc(target, non_existent_id)
    end

    test "doc/3 handles not found with schema/version" do
      non_existent_id = Ecto.UUID.generate()

      assert {:error, :not_found} = Client.doc(Work, 2, non_existent_id)
    end

    test "doc/2 handles bad index" do
      work_id = Ecto.UUID.generate()

      assert {:error, _reason} = Client.doc("BAD_INDEX", work_id)
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

    test "doesn't swap alias if hot swap is incomplete" do
      log =
        capture_log(fn ->
          Client.hot_swap(Work, 2, fn _index ->
            {:incomplete, "Some documents are missing"}
          end)
        end)

      assert log =~ ~r/Incomplete hot swap/
      assert log =~ ~r/Some documents are missing/
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
