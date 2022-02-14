defmodule MeadowWeb.Schema.Query.IngestErrorsTest do
  use Meadow.DataCase
  use Meadow.IngestCase
  use MeadowWeb.ConnCase, async: true
  use Wormwood.GQLCase

  alias Meadow.Ingest.Rows

  load_gql(MeadowWeb.Schema, "test/gql/GetIngestErrors.gql")

  describe "ingest with errors" do
    test "duplicate FileSet accession number", %{ingest_sheet: sheet} do
      accession_number =
        Rows.list_ingest_sheet_rows(sheet: sheet)
        |> Enum.at(1)
        |> Map.get(:file_set_accession_number)

      file_set_fixture(%{accession_number: accession_number})
      sheet = create_works(sheet)

      {:ok, result} = query_gql(variables: %{"sheetId" => sheet.id}, context: gql_context())

      with results <- get_in(result, [:data, "ingestSheetErrors"]) do
        skipped = results |> Enum.filter(&(&1["outcome"] == "SKIPPED"))
        errors = results |> Enum.filter(&(&1["outcome"] == "ERROR"))

        assert length(results) == 5
        assert length(errors) == 1
        assert length(skipped) == 4

        with error <- List.first(errors) do
          assert error["rowNumber"] == 2
          assert error["action"] == "CreateFileSet"
          assert error["errors"] == "accession_number: has already been taken"
        end
      end
    end

    test "duplicate Work accession number", %{ingest_sheet: sheet} do
      accession_number =
        Rows.list_ingest_sheet_rows(sheet: sheet)
        |> Enum.at(4)
        |> Map.get(:fields)
        |> Enum.find(fn %{header: header} -> header == "work_accession_number" end)
        |> Map.get(:value)

      work_fixture(%{accession_number: accession_number})
      sheet = create_works(sheet)

      {:ok, result} = query_gql(variables: %{"sheetId" => sheet.id}, context: gql_context())

      with results <- get_in(result, [:data, "ingestSheetErrors"]) do
        skipped = results |> Enum.filter(&(&1["outcome"] == "SKIPPED"))
        errors = results |> Enum.filter(&(&1["outcome"] == "ERROR"))

        assert length(results) == 5
        assert length(errors) == 1
        assert length(skipped) == 4

        with error <- List.first(errors) do
          assert error["rowNumber"] == 5
          assert error["action"] == "Create Work"
          assert error["errors"] == "accession_number: has already been taken"
        end
      end
    end
  end
end
