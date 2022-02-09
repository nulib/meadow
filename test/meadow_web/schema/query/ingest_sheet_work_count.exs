defmodule MeadowWeb.Schema.Query.IngestSheetWorkCount do
  use Meadow.IngestCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/IngestSheetWorkCount.gql")

  test "ingestSheetWorkCount query returns total works in an ingest sheet", %{ingest_sheet: sheet} do
    sheet = create_works(sheet)

    {:ok, result} = query_gql(variables: %{"sheetId" => sheet.id}, context: gql_context())

    with result <- get_in(result, [:data, "ingestSheetWorkCount", "totalWorks"]) do
      assert result == 2
    end

    with result <- get_in(result, [:data, "ingestSheetWorkCount", "totalFileSets"]) do
      assert result == 8
    end

    with result <- get_in(result, [:data, "ingestSheetWorkCount", "pass"]) do
      assert result == 8
    end

    with result <- get_in(result, [:data, "ingestSheetWorkCount", "fail"]) do
      assert result == 0
    end
  end
end
