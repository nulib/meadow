defmodule Meadow.Ingest.ValidatorTest do
  use Meadow.DataCase
  use Meadow.S3Case

  alias Meadow.Ingest.{Rows, Sheets, Validator}

  @sheet_path "/validator_test/"
  @uploads_bucket Meadow.Config.upload_bucket()
  @ingest_bucket Meadow.Config.ingest_bucket()
  @image_fixture "test/fixtures/coffee.tif"
  @json_fixture "test/fixtures/details.json"
  @video_fixture "test/fixtures/small.m4v"
  @vtt_fixture "test/fixtures/Donohue_002_01.vtt"
  @invalid_vtt_fixture "test/fixtures/invalid.vtt"

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

    upload_object(
      @ingest_bucket,
      "#{project.folder}/details.json",
      File.read!(@json_fixture)
    )

    upload_object(
      @ingest_bucket,
      "#{project.folder}/small.m4v",
      File.read!(@video_fixture)
    )

    upload_object(
      @ingest_bucket,
      "#{project.folder}/Donohue_002_01.vtt",
      File.read!(@vtt_fixture)
    )

    upload_object(
      @ingest_bucket,
      "#{project.folder}/invalid.vtt",
      File.read!(@invalid_vtt_fixture)
    )

    on_exit(fn ->
      delete_object(@uploads_bucket, @sheet_path <> context.sheet)
      delete_object(@ingest_bucket, "#{project.folder}/coffee.tif")
      delete_object(@ingest_bucket, "#{project.folder}/details.json")
      delete_object(@ingest_bucket, "#{project.folder}/small.m4v")
      delete_object(@ingest_bucket, "#{project.folder}/Donohue_002_01.vtt")
      delete_object(@ingest_bucket, "#{project.folder}/invalid.vtt")
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
        "Required header missing: file_accession_number",
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

  @tag sheet: "ingest_sheet_accession_exists.csv"
  test "fails when accession_number already exists", context do
    file_set_fixture(%{accession_number: "6777"})
    assert(Validator.result(context.sheet.id) == "fail")
    ingest_sheet = Validator.validate(context.sheet.id)

    assert(ingest_sheet.status == "row_fail")
  end

  @tag sheet: "ingest_sheet_work_accession_exists.csv"
  test "fails when work_accession_number already exists", context do
    work_fixture(%{accession_number: "6779"})
    assert(Validator.result(context.sheet.id) == "fail")
    ingest_sheet = Validator.validate(context.sheet.id)

    assert(ingest_sheet.status == "row_fail")
  end

  @tag sheet: "ingest_sheet_duplicate_accession.csv"
  test "fails with duplicate accession_number", context do
    assert(Validator.result(context.sheet.id) == "fail")
    ingest_sheet = Validator.validate(context.sheet.id) |> Repo.preload(:ingest_sheet_rows)

    assert(ingest_sheet.status == "row_fail")

    ingest_sheet
    |> Map.get(:ingest_sheet_rows)
    |> Enum.each(fn
      %{file_set_accession_number: "Donohue_001_02", errors: [error]} ->
        assert error.message == "file_accession_number: Donohue_001_02 is duplicated on rows 2, 3"

      %{file_set_accession_number: "Donohue_002_01", errors: [error]} ->
        assert error.message ==
                 "file_accession_number: Donohue_002_01 is duplicated on rows 5, 6, 7"

      row ->
        assert row.errors == []
    end)
  end

  @tag sheet: "ingest_sheet_missing_work_type.csv"
  test "fails with missing work type", context do
    assert(Validator.result(context.sheet.id) == "fail")
    ingest_sheet = Validator.validate(context.sheet.id)

    assert(ingest_sheet.status == "row_fail")
  end

  @tag sheet: "ingest_sheet_invalid_work_image.csv"
  test "fails when specified work_image has an invalid role", context do
    assert(Validator.result(context.sheet.id) == "fail")
    ingest_sheet = Validator.validate(context.sheet.id)

    assert(ingest_sheet.status == "row_fail")
  end

  @tag sheet: "ingest_sheet_missing_webvtt.csv"
  test "fails when the webvtt structure file is missing", context do
    assert(Validator.result(context.sheet.id) == "fail")
    ingest_sheet = Validator.validate(context.sheet.id)

    assert(ingest_sheet.status == "row_fail")
  end

  @tag sheet: "ingest_sheet_invalid_webvtt.csv"
  test "fails when the webvtt structure file is invalid", context do
    assert(Validator.result(context.sheet.id) == "fail")
    ingest_sheet = Validator.validate(context.sheet.id)

    assert(ingest_sheet.status == "row_fail")
  end

  @tag sheet: "ingest_sheet_wrong_mime_type.csv"
  test "fails when the a file set has an invalid mime type", context do
    assert(Validator.result(context.sheet.id) == "fail")

    ingest_sheet = Validator.validate(context.sheet.id)
    assert(ingest_sheet.status == "row_fail")

    assert [%{count: 1, state: "fail"}, %{count: 8, state: "pass"}] =
             Sheets.list_ingest_sheet_row_counts(ingest_sheet.id)

    %{
      errors: [
        %Meadow.Ingest.Schemas.Row.Error{
          field: "filename",
          message: message
        }
      ]
    } = Rows.get_row(ingest_sheet.id, 9)

    assert String.contains?(message, [
             "Mime-type:",
             "not accepted for work type: AUDIO and file set role: A"
           ])
  end
end
