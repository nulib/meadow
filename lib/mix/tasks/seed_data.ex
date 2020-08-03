defmodule Mix.Tasks.Meadow.SeedData do
  @shortdoc "Ingest data into meadow from a CSV using the Pipeline"

  @moduledoc """
  A Mix task to ingest data into Meadow from a local CSV file using the Pipeline.
  Uploads files listed in the CSV to the configured ingest bucket.
  Validates and approves the ingest, while logging progress with percentages.

    mix meadow.seed_data export_name

  The task creates a project called "Seed Data Project", and an ingest sheet with the
  basename of the CSV provided to the task.

  Note: if the task is run a second time, you should receive an error saying the sheet already exists.
  """

  use Mix.Task

  alias Meadow.{Config, Repo}
  alias Meadow.Data.Indexer
  alias Meadow.Ingest.{Progress, Projects, Rows, Sheets, SheetsToWorks, Validator}
  alias Meadow.Utils.MetadataGenerator

  require Logger

  @project_title "Seed Data Project"

  def run([export_name]), do: ingest_from_csv(Path.join("priv/seed_data", "#{export_name}.csv"))

  defp ingest_from_csv(csv_path) do
    Mix.Task.run("app.start")
    Logger.configure(level: :info)
    Logger.metadata(seed: csv_path)
    Logger.info("Seeding Meadow Data...")

    validation =
      csv_path
      |> check_for_existing_ingest_sheet()
      |> upload_files()
      |> create_ingest_sheet()
      |> validate_ingest_sheet()

    case validation do
      {:ok, sheet} -> approve_ingest_sheet(sheet)
      {:error, sheet} -> log_ingest_sheet_errors(sheet)
    end
  end

  defp check_for_existing_ingest_sheet(csv_path) do
    case Sheets.get_ingest_sheet_by_title(Path.basename(csv_path)) do
      nil ->
        csv_path

      _ ->
        Logger.error("Sheet already exists: #{Path.basename(csv_path)}")
        exit(:normal)
    end
  end

  defp log_ingest_sheet_errors(sheet) do
    Logger.error("Ingest sheet has errors:")
    Enum.each(sheet.file_errors, &Logger.error/1)

    Rows.list_ingest_sheet_rows(sheet: sheet)
    |> Enum.each(&log_row_errors/1)
  end

  defp log_row_errors(%{errors: []}), do: :noop

  defp log_row_errors(%{row: row, errors: errors}) do
    Enum.each(errors, &Logger.error("Row #{row}: #{&1.message}"))
  end

  defp approve_ingest_sheet(sheet) do
    Logger.info("Approving ingest sheet and starting ingest...")

    with {:ok, sheet} <- Sheets.update_ingest_sheet_status(sheet, "approved") do
      sheet
      |> SheetsToWorks.create_works_from_ingest_sheet()
      |> SheetsToWorks.send_to_pipeline()

      Logger.info("Ingest sheet sent to pipeline. Waiting for ingest to complete.")
      wait_for_completion(sheet)

      with works <- Sheets.list_ingest_sheet_works(sheet) do
        Logger.info("Generating random descriptive metadata for #{length(works)} works.")
        MetadataGenerator.generate_descriptive_metadata_for(works)
      end

      Logger.info("Synchronizing Elasticsearch index.")
      Indexer.synchronize_index()
    end
  end

  defp wait_for_completion(sheet) do
    wait_for_completion(sheet, Progress.pipeline_progress(sheet))
  end

  defp wait_for_completion(sheet, %Progress{percent_complete: pct}) do
    if pct >= 100 do
      Logger.info("Ingest complete.")
    else
      Logger.info("#{pct}% complete.")
      :timer.sleep(:timer.seconds(1))
      wait_for_completion(sheet)
    end
  end

  defp find_or_create_project do
    case Projects.get_project_by_title(@project_title) do
      nil ->
        with {:ok, project} <- Projects.create_project(%{title: @project_title}) do
          project
        end

      project ->
        project
    end
  end

  defp validate_ingest_sheet(sheet) do
    Logger.info("Validating ingest sheet...")

    with sheet <- Validator.validate(sheet) do
      case Sheets.find_state(sheet) do
        "pass" -> {:ok, sheet}
        "fail" -> {:error, sheet}
      end
    end
  end

  defp create_ingest_sheet(csv_path) do
    sheet_title = Path.basename(csv_path)
    csv_key = "ingest_sheets/#{sheet_title}"

    Logger.info("Uploading #{csv_key} to upload bucket")

    ExAws.S3.put_object(Config.upload_bucket(), csv_key, File.read!(csv_path))
    |> ExAws.request!()

    {:ok, sheet} =
      Sheets.create_ingest_sheet(%{
        project_id: find_or_create_project() |> Map.get(:id),
        title: sheet_title,
        filename: "s3://#{Config.upload_bucket()}/#{csv_key}"
      })

    sheet |> Repo.preload(:project)
  end

  defp upload_files(csv_path), do: upload_files(csv_path, find_or_create_project())

  defp upload_files(csv_path, project) do
    directory = Path.rootname(csv_path, Path.extname(csv_path))

    with files <- Path.wildcard("#{directory}/*") do
      Logger.info("Uploading #{length(files)} files to ingest bucket")
      Enum.each(files, fn path -> upload_file(path, project) end)
    end

    csv_path
  end

  defp upload_file(path, project) do
    key = [project.folder | Path.split(path) |> Enum.take(-2)] |> Path.join()

    ExAws.S3.put_object(Config.ingest_bucket(), key, File.read!(path))
    |> ExAws.request!()
  end
end
