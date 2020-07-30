defmodule Meadow.Ingest.ValidatorTest do
  use Meadow.DataCase
  use Meadow.S3Case

  alias Meadow.Ingest.Validator

  @sheet_path "/validator_test/"
  @uploads_bucket Meadow.Config.upload_bucket()
  @ingest_bucket Meadow.Config.ingest_bucket()
  @image_fixture "test/fixtures/coffee.tif"

  setup context do
    project =
      project_fixture(%{
        id: "45289196-b5bc-44fd-bd99-dcf033f020f8"
      })

    sheet =
      ingest_sheet_fixture(%{
        title: to_string(context.test),
        project_id: project.id,
        filename: "s3://" <> @uploads_bucket <> @sheet_path <> context.sheet
      })

    upload_object(
      @uploads_bucket,
      @sheet_path <> context.sheet,
      File.read!("test/fixtures/#{context.sheet}")
    )

    upload_object(
      @ingest_bucket,
      "#{project.folder}/coffee.tif",
      File.read!(@image_fixture)
    )

    on_exit(fn ->
      delete_object(@uploads_bucket, @sheet_path <> context.sheet)
      delete_object(@ingest_bucket, "#{project.folder}/coffee.tif")
    end)

    {:ok, %{sheet: sheet, project: project}}
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

  @tag sheet: "missing_ingest_sheet.csv"
  test "fails an ingest sheet the csv is missing", context do
    delete_object(@uploads_bucket, @sheet_path <> "missing_ingest_sheet.csv")
    assert(Validator.result(context.sheet.id) == "fail")
    ingest_sheet = Validator.validate(context.sheet.id)

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
