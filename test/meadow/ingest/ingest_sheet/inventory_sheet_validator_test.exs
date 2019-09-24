defmodule Meadow.Ingest.IngestSheets.IngestSheetValidatorTest do
  use Meadow.DataCase

  alias Meadow.Ingest.{IngestSheets, Projects}
  alias Meadow.Ingest.IngestSheets.IngestSheetValidator

  import Mox

  doctest Meadow.Ingest.IngestSheets.IngestSheetValidator

  @sheet_path "test-uploads/ingest_sheets/"

  setup context do
    {:ok, project} = Projects.create_project(%{title: to_string(context.test)})

    {:ok, sheet} =
      IngestSheets.create_ingest_sheet(%{
        name: to_string(context.test),
        project_id: project.id,
        filename: "s3://" <> @sheet_path <> context.sheet
      })

    http_mock = fn
      :get, url, _, _, _ ->
        file = url |> String.split("/") |> List.last()

        case File.exists?("test/fixtures/#{file}") do
          true -> {:ok, %{status_code: 200, body: File.read!("test/fixtures/#{file}")}}
          false -> {:ok, %{status_code: 404}}
        end

      :head, url, _, _, _ ->
        file = url |> String.split("/") |> List.last()

        case file do
          "Missing_" <> _ -> {:ok, %{status_code: 404}}
          _ -> {:ok, %{status_code: 200}}
        end
    end

    Meadow.ExAwsHttpMock
    |> stub(:request, http_mock)

    {:ok, %{sheet: sheet, project: project}}
  end

  @tag sheet: "ingest_sheet.csv"
  test "fails when the project isn't preloaded", context do
    assert_raise(ArgumentError, "Ingest Sheet association not loaded", fn ->
      IngestSheetValidator.result(context.sheet)
    end)
  end

  @tag sheet: "ingest_sheet.csv"
  test "validates an ingest sheet", context do
    assert(IngestSheetValidator.result(context.sheet.id) == "pass")
  end

  @tag sheet: "ingest_sheet_wrong_headers.csv"
  test "fails an ingest sheet when the headers are wrong", context do
    assert(IngestSheetValidator.result(context.sheet.id) == "fail")
    ingest_sheet = IngestSheetValidator.validate(context.sheet.id)

    assert(
      ingest_sheet.file_errors == [
        "Required header missing: accession_number",
        "Invalid header: not_the_accession_number"
      ]
    )
  end

  @tag sheet: "ingest_sheet_missing_field.csv"
  test "fails an ingest sheet when a field is missing", context do
    assert(IngestSheetValidator.result(context.sheet.id) == "fail")
  end

  @tag sheet: "ingest_sheet_missing_file.csv"
  test "fails an ingest sheet when a file is missing", context do
    assert(IngestSheetValidator.result(context.sheet.id) == "fail")
  end

  @tag sheet: "missing_ingest_sheet.csv"
  test "fails when ingest sheet is missing", context do
    assert(IngestSheetValidator.result(context.sheet.id) == "fail")
    ingest_sheet = IngestSheetValidator.validate(context.sheet.id)

    assert(
      ingest_sheet.file_errors == [
        "Could not load ingest sheet from S3"
      ]
    )
  end
end
