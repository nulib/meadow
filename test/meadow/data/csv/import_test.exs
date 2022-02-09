defmodule Meadow.Data.CSV.ImportTest do
  use Meadow.DataCase
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
end
