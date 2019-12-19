defmodule Meadow.Ingest.ValidatorTest do
  use Meadow.DataCase

  alias Meadow.Ingest.{Projects, Sheets}
  alias Meadow.Ingest.Validator

  import Mox

  doctest Meadow.Ingest.Validator

  @sheet_path "test-uploads/ingest_sheets/"

  setup context do
    {:ok, project} = Projects.create_project(%{title: to_string(context.test)})

    {:ok, sheet} =
      Sheets.create_ingest_sheet(%{
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
      Validator.result(context.sheet)
    end)
  end

  @tag sheet: "ingest_sheet.csv"
  test "validates an ingest sheet", context do
    assert(Validator.result(context.sheet.id) == "pass")
    ingest_sheet = Validator.validate(context.sheet.id)

    assert(ingest_sheet.file_errors == [])

    assert(ingest_sheet.status == "valid")
  end

  @tag sheet: "ingest_sheet_wrong_headers.csv"
  test "fails an ingest sheet when the headers are wrong", context do
    assert(Validator.result(context.sheet.id) == "fail")
    ingest_sheet = Validator.validate(context.sheet.id)

    assert(
      ingest_sheet.file_errors == [
        "Required header missing: accession_number",
        "Invalid header: not_the_accession_number"
      ]
    )

    assert(ingest_sheet.status == "file_fail")
  end

  @tag sheet: "ingest_sheet_missing_field.csv"
  test "fails an ingest sheet when a field is missing", context do
    assert(Validator.result(context.sheet.id) == "fail")
    ingest_sheet = Validator.validate(context.sheet.id)

    assert(ingest_sheet.status == "row_fail")
  end

  @tag sheet: "ingest_sheet_missing_file.csv"
  test "fails an ingest sheet when a file is missing", context do
    assert(Validator.result(context.sheet.id) == "fail")
    ingest_sheet = Validator.validate(context.sheet.id)

    assert(ingest_sheet.status == "row_fail")
  end

  @tag sheet: "missing_ingest_sheet.csv"
  test "fails when ingest sheet is missing", context do
    assert(Validator.result(context.sheet.id) == "fail")
    ingest_sheet = Validator.validate(context.sheet.id)

    assert(
      ingest_sheet.file_errors == [
        "Could not load ingest sheet from S3"
      ]
    )
  end

  @tag sheet: "ingest_sheet_incorrect_role.csv"
  test "fails when ingest sheet has invalid content for role", context do
    assert(Validator.result(context.sheet.id) == "fail")
    ingest_sheet = Validator.validate(context.sheet.id)

    assert(ingest_sheet.status == "row_fail")
  end

  @tag sheet: "ingest_sheet_duplicate_accession.csv"
  test "fails with duplicate accession_number", context do
    file_set_fixture(%{accession_number: "6777"})
    assert(Validator.result(context.sheet.id) == "fail")
    ingest_sheet = Validator.validate(context.sheet.id)

    assert(ingest_sheet.status == "row_fail")
  end

  @tag sheet: "ingest_sheet_duplicate_work_accession.csv"
  test "fails with duplicate work_accession_number", context do
    work_fixture(%{accession_number: "6779"})
    assert(Validator.result(context.sheet.id) == "fail")
    ingest_sheet = Validator.validate(context.sheet.id)

    assert(ingest_sheet.status == "row_fail")
  end
end
