defmodule Meadow.Ingest.IngestJobs.InventoryValidatorTest do
  use Meadow.DataCase

  alias Meadow.Ingest.{IngestJobs, Projects}
  alias Meadow.Ingest.IngestJobs.InventoryValidator

  import Mox

  doctest Meadow.Ingest.IngestJobs.InventoryValidator

  @sheet_path "test-uploads/inventory_sheets/"

  setup context do
    {:ok, project} = Projects.create_project(%{title: to_string(context.test)})

    {:ok, job} =
      IngestJobs.create_ingest_job(%{
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

    {:ok, %{job: job, project: project}}
  end

  @tag sheet: "inventory_sheet.csv"
  test "fails when the project isn't preloaded", context do
    assert_raise(ArgumentError, "Ingest Job association not loaded", fn ->
      InventoryValidator.result(context.job)
    end)
  end

  @tag sheet: "inventory_sheet.csv"
  test "validates an inventory sheet", context do
    assert(InventoryValidator.result(context.job.id) == "pass")
  end

  @tag sheet: "inventory_sheet_wrong_headers.csv"
  test "fails an inventory sheet when the headers are wrong", context do
    assert(InventoryValidator.result(context.job.id) == "fail")
    ingest_job = InventoryValidator.validate(context.job.id)

    assert(
      ingest_job.file_errors == [
        "Required header missing: accession_number",
        "Invalid header: not_the_accession_number"
      ]
    )
  end

  @tag sheet: "inventory_sheet_missing_field.csv"
  test "fails an inventory sheet when a field is missing", context do
    assert(InventoryValidator.result(context.job.id) == "fail")
  end

  @tag sheet: "inventory_sheet_missing_file.csv"
  test "fails an inventory sheet when a file is missing", context do
    assert(InventoryValidator.result(context.job.id) == "fail")
  end

  @tag sheet: "missing_inventory_sheet.csv"
  test "fails when inventory sheet is missing", context do
    assert(InventoryValidator.result(context.job.id) == "fail")
    ingest_job = InventoryValidator.validate(context.job.id)

    assert(
      ingest_job.file_errors == [
        "Could not load ingest sheet from S3"
      ]
    )
  end
end
