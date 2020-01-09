defmodule Meadow.Ingest.RowsTest do
  use Meadow.DataCase
  alias Meadow.Ingest.Rows

  @fixture "test/fixtures/ingest_sheet.csv"

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
