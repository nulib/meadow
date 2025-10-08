defmodule Meadow.Search.SliceTest do
  use Meadow.DataCase
  use Meadow.IndexCase

  alias Meadow.Data.Indexer
  alias Meadow.Data.Schemas.Work
  alias Meadow.Search.Config, as: SearchConfig
  alias Meadow.Search.Slice

  @v2_work_index SearchConfig.alias_for(Work, 2)
  @query ~s({"query": {"match_all": {}}, "_source": ["accession_number"], "size": 10000})

  describe "results/1" do
    setup do
      1..37
      |> Enum.each(&work_fixture(%{accession_number: "TEST_WORK_#{&1}"}))

      Indexer.synchronize_index()
      slice = Slice.paginate(@query, @v2_work_index, 5)
      on_exit(fn -> Slice.finish(slice) end)
      {:ok, %{slice: slice}}
    end

    test "paginate/3", %{slice: %Slice{index: index, max_slices: max}} do
      assert index == @v2_work_index
      assert max == 8
    end

    test "paginate/3 with map query" do
      slice = Slice.paginate(Jason.decode!(@query, keys: :atoms), @v2_work_index, 5)
      assert slice.max_slices == 8
    end

    test "paginate/3 when slice size > result size" do
      slice = Slice.paginate(@query, @v2_work_index, 3_000)
      assert slice.max_slices == 1
      assert {:ok, hits} = Slice.slice(slice, 0)
      assert length(hits) == 37
    end

    test "slice/2", %{slice: slice} do
      counts =
        for i <- 0..7 do
          {:ok, hits} = Slice.slice(slice, i)
          length(hits)
        end

      assert Enum.sum(counts) == 37
    end

    test "slice/2 with invalid slice number", %{slice: slice} do
      assert {:error, _} = Slice.slice(slice, 8)
      assert {:error, _} = Slice.slice(slice, -1)
    end
  end

  describe "errors" do
    test "paginate/3 with invalid JSON" do
      assert {:error, _} = Slice.paginate("invalid json", @v2_work_index)
    end

    test "paginate/3 with missing query key" do
      assert {:error, _} = Slice.paginate(%{invalid: "query"}, @v2_work_index)
    end

    test "paginate/3 with invalid query" do
      assert {:error, _} =
               Slice.paginate(%{query: %{match_this: "not a valid query"}}, @v2_work_index)
    end
  end
end
