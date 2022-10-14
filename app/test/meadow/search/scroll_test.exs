defmodule Meadow.Search.ScrollTest do
  use Meadow.DataCase
  use Meadow.IndexCase

  alias Meadow.Data.Indexer
  alias Meadow.Search.Scroll

  @query ~s'{"query":{"term":{"model.name.keyword":{"value":"Work"}}}}'

  describe "results/1" do
    setup do
      1..50
      |> Enum.each(&work_fixture(%{accession_number: "TEST_WORK_#{&1}"}))

      Indexer.synchronize_index()
      :ok
    end

    test "produces a stream" do
      assert Scroll.results(@query) |> Enum.into([]) |> length() == 50
    end
  end
end
