defmodule MeadowWeb.Schema.Query.IngestErrorsTest do
  use Meadow.IngestCase
  use MeadowWeb.ConnCase
  use Wormwood.GQLCase

  load_gql(MeadowWeb.Schema, "test/gql/GetIngestErrors.gql")

  describe "ingest with errors" do
    test "duplicate FileSet accession number", %{ingest_sheet: sheet} do
      file_set_fixture(%{accession_number: "Donohue_001_02"})
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
      work_fixture(%{accession_number: "Donohue_002"})
      sheet = create_works(sheet)

      {:ok, result} = query_gql(variables: %{"sheetId" => sheet.id}, context: gql_context())

      with results <- get_in(result, [:data, "ingestSheetErrors"]) do
        skipped = results |> Enum.filter(&(&1["outcome"] == "SKIPPED"))
        errors = results |> Enum.filter(&(&1["outcome"] == "ERROR"))

        assert length(results) == 4
        assert length(errors) == 1
        assert length(skipped) == 3

        with error <- List.first(errors) do
          assert error["rowNumber"] == 5
          assert error["action"] == "Create Work"
          assert error["errors"] == "accession_number: has already been taken"
        end
      end
    end
  end
end
