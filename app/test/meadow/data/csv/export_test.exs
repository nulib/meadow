defmodule Meadow.Data.CSV.ExportTest do
  use Meadow.DataCase
  use Meadow.IndexCase

  alias Meadow.Arks
  alias Meadow.Data.{CSV.Export, Indexer, Works}
  alias NimbleCSV.RFC4180, as: CSV

  import Assertions

  @query %{query: %{match_all: %{}}}
  @sample_record exs_fixture("test/fixtures/csv/export_fixture_31.exs")

  setup do
    prewarm_controlled_term_cache()
    collection = collection_fixture()

    exs_fixture("test/fixtures/csv/work_fixtures.exs")
    |> Enum.each(fn work_data ->
      work_data
      |> Map.put(:collection_id, collection.id)
      |> Works.create_work!()
      |> Arks.mint_ark()
    end)

    Indexer.synchronize_index()

    {:ok, %{collection: collection}}
  end

  test "export_works/0", %{collection: collection} do
    result = Export.generate_csv(@query)
    [query | [csv | []]] = String.split(result, ~r/[\r\n]+/, parts: 2)

    [header | data] = CSV.parse_string(csv, skip_headers: false)

    sample_row = Enum.find(data, &Enum.member?(&1, @sample_record[:accession_number]))

    sample_record = Enum.zip(header, sample_row) |> Enum.into(%{})

    generated_ids = data |> Enum.map(&List.first/1)
    work_ids = Works.list_works() |> Enum.map(&Map.get(&1, :id))
    assert_lists_equal(generated_ids, work_ids)

    assert query =~ "match_all"

    assert Enum.member?(header, "id")
    assert {:ok, _} = Map.get(sample_record, "id") |> Ecto.UUID.dump()

    assert Enum.member?(header, "collection_id")
    assert Map.get(sample_record, "collection_id") == collection.id

    assert Enum.member?(header, "ark")
    assert Map.get(sample_record, "ark") |> String.starts_with?("ark:/")

    @sample_record
    |> Enum.each(fn {field, expected_value} ->
      assert Enum.member?(header, to_string(field))
      assert Map.get(sample_record, to_string(field)) == expected_value
    end)
  end
end
