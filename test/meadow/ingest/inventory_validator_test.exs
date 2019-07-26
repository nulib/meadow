defmodule Meadow.Ingest.InventoryValidatorTest do
  use Meadow.DataCase

  alias Meadow.Ingest
  alias Meadow.Ingest.InventoryValidator

  import Mox

  doctest Meadow.Ingest.InventoryValidator

  @files [
    "Donohue_001_01.tif",
    "Donohue_001_02.tif",
    "Donohue_001_03.tif",
    "Donohue_001_04.tif",
    "Donohue_002_01.tif",
    "Donohue_002_02.tif",
    "Donohue_002_03.tif"
  ]
  @sheet_path "test-uploads/inventory_sheets/"

  setup context do
    {:ok, project} = Ingest.create_project(%{title: to_string(context.test)})

    {:ok, job} =
      Ingest.create_ingest_job(%{
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

        case @files |> Enum.any?(&(&1 == file)) do
          true -> {:ok, %{status_code: 200}}
          false -> {:ok, %{status_code: 404}}
        end
    end

    Meadow.ExAwsHttpMock
    |> stub(:request, http_mock)

    {:ok, %{job: job, project: project}}
  end

  @tag sheet: "inventory_sheet.csv"
  test "fails when the project isn't preloaded", context do
    assert_raise(ArgumentError, "Ingest Job association not loaded", fn ->
      InventoryValidator.validate_job(context.job)
    end)
  end

  @tag sheet: "inventory_sheet.csv"
  test "validates an inventory sheet", context do
    assert(InventoryValidator.validate(context.job.id) == :pass)
  end

  @tag sheet: "inventory_sheet_wrong_headers.csv"
  test "fails an inventory sheet when the headers are wrong", context do
    assert(InventoryValidator.validate(context.job.id) == :fail)
  end

  @tag sheet: "inventory_sheet_missing_field.csv"
  test "fails an inventory sheet when a field is missing", context do
    assert(InventoryValidator.validate(context.job.id) == :fail)
  end

  @tag sheet: "inventory_sheet_missing_file.csv"
  test "fails an inventory sheet when a file is missing", context do
    assert(InventoryValidator.validate(context.job.id) == :fail)
  end

  @tag sheet: "missing_inventory_sheet.csv"
  test "fails when inventory sheet is missing", context do
    assert(InventoryValidator.validate(context.job.id) == :fail)
  end
end
