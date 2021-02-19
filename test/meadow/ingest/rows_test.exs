defmodule Meadow.Ingest.RowsTest do
  use Meadow.DataCase
  alias Meadow.Ingest.Rows

  @fixture "test/fixtures/ingest_sheet.csv"

  describe "list_ingest_sheet_rows/1" do
    setup %{criteria: criteria} do
      criteria = Keyword.put_new(criteria, :sheet, ingest_sheet_rows_fixture(@fixture))

      {
        :ok,
        result: Rows.list_ingest_sheet_rows(criteria) |> Enum.map(fn r -> r.row end)
      }
    end

    @tag criteria: []
    test "fetch all rows for sheet", %{result: result} do
      assert result == [1, 2, 3, 4, 5, 6, 7]
    end

    @tag criteria: [state: ["pending"]]
    test "fetch all rows in pending state", %{result: result} do
      assert result == [1, 2, 3, 4, 5, 6, 7]
    end

    @tag criteria: [start: 3]
    test "fetch rows with a start index", %{result: result} do
      assert result == [3, 4, 5, 6, 7]
    end

    @tag criteria: [limit: 3]
    test "fetch rows with a limit", %{result: result} do
      assert result == [1, 2, 3]
    end
  end

  describe "grouping by work" do
    setup do
      sheet = ingest_sheet_rows_fixture(@fixture) |> Repo.preload(:ingest_sheet_rows)

      prefix =
        sheet.ingest_sheet_rows
        |> List.first()
        |> Map.get(:file_set_accession_number)
        |> String.split("_")
        |> List.first()

      {:ok, %{prefix: prefix, sheet: sheet}}
    end

    test "get_rows_by_work_accession_number/2", %{prefix: prefix, sheet: sheet} do
      with rows <- Rows.get_rows_by_work_accession_number(sheet.id, "#{prefix}_Donohue_001") do
        assert length(rows) == 4

        Enum.each(rows, fn row ->
          assert String.starts_with?(row.file_set_accession_number, "#{prefix}_Donohue_001_")
        end)
      end

      with rows <- Rows.get_rows_by_work_accession_number(sheet.id, "#{prefix}_Donohue_002") do
        assert length(rows) == 3

        Enum.each(rows, fn row ->
          assert String.starts_with?(row.file_set_accession_number, "#{prefix}_Donohue_002_")
        end)
      end
    end
  end
end
