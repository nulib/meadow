defmodule Meadow.Data.CSV.ImportTest do
  use Meadow.DataCase
  use Meadow.GeoNamesCase
  alias Meadow.Data.CSV.Import

  import Assertions

  @sample_record exs_fixture("test/fixtures/csv/import_fixture_31.exs")

  describe "csv files" do
    setup do
      {:ok,
       %{
         subject:
           File.stream!("test/fixtures/csv/sheets/valid.csv")
           |> Import.read_csv()
       }}
    end

    test "fields/1", %{subject: subject} do
      assert_lists_equal(subject.headers, Import.fields())
    end

    test "stream/1", %{subject: subject} do
      assert subject
             |> Import.stream()
             |> Enum.at(31)
             |> Map.delete(:id)
             |> Map.delete(:accession_number) == @sample_record
    end
  end

  test "decode boolean values" do
    booleans =
      File.stream!("test/fixtures/csv/sheets/boolean_values.csv")
      |> Import.read_csv()
      |> Import.stream()
      |> Enum.map(& &1.published)

    assert booleans == [
             true,
             true,
             true,
             true,
             true,
             true,
             true,
             true,
             false,
             false,
             false,
             false,
             false,
             false,
             "unknown"
           ]
  end

  test "nav_place import from CSV" do
    # The exported CSV value with pipe-separated GeoNames IDs
    csv_value = "https://sws.geonames.org/4887398/ | https://sws.geonames.org/2110435/"

    # Create a temporary CSV file for testing
    {:ok, path} = Plug.Upload.random_file("nav_place_test")

    # Get all field names to ensure we have the right number of columns
    field_count = length(Import.fields())

    # The first line must be the JSON query, properly CSV-escaped
    query_json = Jason.encode!(%{"query" => %{"match_all" => %{}}})
    query_row = [query_json | List.duplicate("", field_count - 1)]

    # Create header row with our three fields plus empty strings for the rest
    field_names = Import.fields() |> Enum.map(&Atom.to_string/1)

    # Create data row - most fields empty, just id, accession_number, and nav_place filled in
    data_row = field_names |> Enum.map(fn
      "id" -> "test-id-123"
      "accession_number" -> "TEST_ACC"
      "nav_place" -> csv_value
      _ -> ""
    end)

    csv_content = NimbleCSV.RFC4180.dump_to_iodata([
      query_row,
      field_names,
      data_row
    ])

    File.write!(path, csv_content)

    # Test that the CSV value imports correctly
    imported =
      File.stream!(path)
      |> Import.read_csv()
      |> Import.stream()
      |> Enum.at(0)

    # Verify the imported nav_place has the correct structure
    assert is_list(imported.descriptive_metadata.nav_place)
    assert length(imported.descriptive_metadata.nav_place) == 2

    # Verify both places were imported with correct IDs
    place_ids =
      imported.descriptive_metadata.nav_place
      |> Enum.map(& &1["id"])
      |> Enum.sort()

    assert place_ids == [
             "https://sws.geonames.org/2110435/",
             "https://sws.geonames.org/4887398/"
           ]

    # Verify places have the expected structure
    chicago =
      Enum.find(
        imported.descriptive_metadata.nav_place,
        &(&1["id"] == "https://sws.geonames.org/4887398/")
      )

    assert chicago["label"] == "Chicago"
    assert is_list(chicago["coordinates"])
  end
end
