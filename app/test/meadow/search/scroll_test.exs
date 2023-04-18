defmodule Meadow.Search.ScrollTest do
  use Meadow.DataCase
  use Meadow.IndexCase

  alias Meadow.Data.Indexer
  alias Meadow.Data.Schemas.Work
  alias Meadow.Search.Config, as: SearchConfig
  alias Meadow.Search.Scroll

  @v2_work_index SearchConfig.alias_for(Work, 2)
  @query ~s'{"query":{"match_all":{}}}'

  describe "results/1" do
    setup do
      1..50
      |> Enum.each(&work_fixture(%{accession_number: "TEST_WORK_#{&1}"}))

      Indexer.synchronize_index()
      :ok
    end

    test "produces a stream" do
      assert {:ok, count} = indexed_doc_count(@v2_work_index)
      assert Scroll.results(@query, @v2_work_index) |> Enum.into([]) |> length() == count
    end
  end
end
