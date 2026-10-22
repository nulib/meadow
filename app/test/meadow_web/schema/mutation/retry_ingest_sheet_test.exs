defmodule MeadowWeb.Schema.Mutation.RetryIngestSheetTest do
  use Meadow.DataCase
  use MeadowWeb.ConnCase, async: false
  use Wormwood.GQLCase

  alias Meadow.Data.ActionStates
  alias Meadow.Ingest.{Rows, Sheets}
  alias Meadow.Pipeline.Actions.{CopyFileToPreservation, IngestFileSet}

  load_gql(MeadowWeb.Schema, "test/gql/RetryIngestSheet.gql")

  setup do
    sheet = ingest_sheet_rows_fixture("test/fixtures/ingest_sheet.csv")
    [row | _] = Rows.list_ingest_sheet_rows(sheet: sheet)

    file_set =
      file_set_fixture(%{
        accession_number: row.file_set_accession_number,
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        core_metadata: %{
          location: "s3://test-ingest/retry/test.tif",
          original_filename: "test.tif",
          mime_type: "image/tiff"
        }
      })

    {:ok, _row} = Rows.associate_file_set_with_row(row, file_set)

    {:ok, sheet: sheet, file_set: file_set}
  end

  test "should be a valid mutation", %{sheet: sheet, file_set: file_set} do
    ActionStates.set_state!(file_set, IngestFileSet, "ok")
    ActionStates.set_state!(file_set, CopyFileToPreservation, "error", "it broke")
    {:ok, _} = Sheets.update_ingest_sheet_status(sheet, "completed_error")

    assert {:ok, query_data} =
             query_gql(
               variables: %{"sheetId" => sheet.id},
               context: gql_context()
             )

    assert get_in(query_data, [:data, "retryIngestSheet", "id"]) == sheet.id
    assert get_in(query_data, [:data, "retryIngestSheet", "status"]) == "APPROVED"
    refute ActionStates.error?(file_set.id)
  end

  test "returns an error when nothing has failed", %{sheet: sheet, file_set: file_set} do
    ActionStates.set_state!(file_set, IngestFileSet, "ok")

    assert {:ok, query_data} =
             query_gql(
               variables: %{"sheetId" => sheet.id},
               context: gql_context()
             )

    assert [%{message: message} | _] = query_data[:errors]
    assert message =~ "no failed file sets to retry"
  end

  test "should reject users below editor", %{sheet: sheet} do
    assert {:ok, result} =
             query_gql(
               variables: %{"sheetId" => sheet.id},
               context: gql_context(%{role: :user})
             )

    assert %{errors: [%{message: "Forbidden", status: 403}]} = result
  end
end
