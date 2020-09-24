defmodule Meadow.Ingest.SheetsToWorksTest do
  use Meadow.DataCase

  alias Meadow.Data.{FileSets, Works}
  alias Meadow.Ingest
  alias Meadow.Ingest.{Sheets, SheetsToWorks}
  alias Meadow.Repo

  @fixture "test/fixtures/ingest_sheet.csv"
  @fixture_works 2
  @fixture_file_sets 7

  setup do
    sheet = ingest_sheet_rows_fixture(@fixture)

    {:ok, sheet: sheet}
  end

  test "create works from ingest sheet", %{sheet: sheet} do
    SheetsToWorks.create_works_from_ingest_sheet(sheet, :sync)
    sheet = sheet |> Repo.preload(:works)
    assert length(sheet.works) == @fixture_works
    assert length(Works.list_works()) == @fixture_works
    assert length(Sheets.list_ingest_sheet_works(sheet)) == @fixture_works
    assert length(FileSets.list_file_sets()) == @fixture_file_sets
    assert length(Repo.preload(sheet, :works).works) == @fixture_works
    assert length(Ingest.get_file_sets_and_rows(sheet)) == @fixture_file_sets
  end
end
