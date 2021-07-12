defmodule Meadow.Ingest.WorkCreator do
  @moduledoc """
  IntervalTask to create works from pending ingest sheet rows
  """
  use Meadow.Utils.Logging

  import Ecto.Query, warn: false

  alias Meadow.Config
  alias Meadow.Data.{ActionStates, FileSets, Works}
  alias Meadow.Data.Schemas.{FileSet, Work}
  alias Meadow.Ingest.{Progress, Rows, Sheets}
  alias Meadow.Ingest.Schemas.Row
  alias Meadow.IntervalTask
  alias Meadow.Pipeline
  alias Meadow.Repo
  alias Meadow.Utils.Truth

  use IntervalTask, default_interval: 500, function: :create_works

  require Logger

  @impl IntervalTask
  def initial_state(args) do
    %{batch_size: Keyword.get(args, :batch_size, 20)}
  end

  @doc """
  Turn a batch of pending work rows into works
  """
  def create_works(state) do
    with_log_metadata module: __MODULE__ do
      with_log_level :info do
        state
        |> get_and_update_pending_work_rows()
        |> handle_result()
      end
    end

    {:noreply, state}
  end

  defp get_and_update_pending_work_rows(state) do
    Repo.transaction(fn ->
      Progress.get_and_lock_pending_work_entries(state.batch_size)
      |> Progress.update_entries("CreateWork", "processing")
    end)
  end

  defp handle_result({:ok, []}), do: []

  defp handle_result({:ok, progress_rows}) do
    Logger.enable(self())
    Logger.info("Creating #{length(progress_rows)} works")
    create_works_from_rows(progress_rows |> Repo.preload(row: :sheet))
  end

  defp handle_result({:error, message}) do
    Logger.error("Problem processing work entries: #{inspect(message)}")
    []
  end

  @doc """
  Create works from pending `CreateWork` progress rows
  """
  def create_works_from_rows(work_rows) do
    work_rows
    |> Enum.map(fn pending_work_row ->
      sheet = pending_work_row.row.sheet
      work_row = pending_work_row.row
      work_accession_number = work_row |> Row.field_value(:work_accession_number)
      file_set_rows = Rows.get_rows_by_work_accession_number(sheet.id, work_accession_number)
      ingest_work({work_row, file_set_rows}, sheet)
    end)
  end

  # Send a single work to the ingest pipeline with the proper
  # ingest sheet metadata
  defp send_work_to_pipeline(ingest_sheet, work, file_set_rows) do
    work.file_sets
    |> Enum.zip(file_set_rows)
    |> Enum.each(fn {%FileSet{id: file_set_id, role: role}, %Row{row: row_num}} ->
      Pipeline.kickoff(file_set_id, %{
        context: "Sheet",
        role: role.id,
        ingest_sheet: ingest_sheet.id,
        ingest_sheet_row: row_num
      })
    end)

    work
  end

  # Ingest a single work and update its status inside a single atomic transaction
  defp ingest_work({work_row, file_set_rows}, ingest_sheet) do
    accession_number = work_row |> Row.field_value(:work_accession_number)
    Logger.info("Creating work #{accession_number} with #{length(file_set_rows)} file sets")

    ingest_bucket = Config.ingest_bucket()

    attrs = %{
      accession_number: accession_number,
      file_sets:
        file_set_rows
        |> Enum.map(fn row ->
          file_path = Row.field_value(row, :filename)
          location = "s3://#{ingest_bucket}/#{file_path}"

          structure_attributes =
            structure_attributes(Row.field_value(row, :structure), ingest_sheet)

          %{
            accession_number: row |> Row.field_value(:file_accession_number),
            role: %{scheme: "file_set_role", id: row |> Row.field_value(:role)},
            core_metadata: %{
              description: row |> Row.field_value(:description),
              location: location,
              original_filename: Path.basename(file_path),
              label: row |> Row.field_value(:label)
            },
            structural_metadata: structure_attributes
          }
        end),
      ingest_sheet_id: ingest_sheet.id,
      published: false,
      visibility: %{id: "RESTRICTED", scheme: "visibility"},
      work_type: %{id: work_row |> Row.field_value(:work_type), scheme: "work_type"}
    }

    on_complete = fn work ->
      work = set_work_image(work, file_set_rows)
      Progress.update_entry(List.first(file_set_rows), "CreateWork", "ok")
      ActionStates.set_state!(work, "Create Work", "ok")
      send_work_to_pipeline(ingest_sheet, work, file_set_rows)
    end

    case Works.ensure_create_work(attrs, on_complete) do
      {:ok, %Work{} = work} ->
        work

      {:error, changeset} ->
        Progress.update_entry(List.first(file_set_rows), "CreateWork", "error")

        file_set_rows
        |> Enum.each(fn %{row: row_num} ->
          Progress.abort_remaining_pending_entries(%{
            ingest_sheet: ingest_sheet.id,
            ingest_sheet_row: row_num
          })
        end)

        create_changeset_errors(changeset, file_set_rows)
    end
  end

  defp structure_attributes("", _sheet), do: %{type: nil, value: nil}

  defp structure_attributes(path, sheet) do
    sheet_with_project = Sheets.get_ingest_sheet_with_project!(sheet.id)

    case Meadow.Config.ingest_bucket()
         |> ExAws.S3.get_object("#{sheet_with_project.project.folder}/#{path}")
         |> ExAws.request() do
      {:ok, vtt} ->
        %{type: "webvtt", value: vtt.body}

      {:error, {:http_error, 404, _}} ->
        Logger.error(".vtt file not found at #{sheet_with_project.project.folder}/#{path}")
        %{type: nil, value: nil}

      {:error, other} ->
        Logger.error(inspect(other))
        %{type: nil, value: nil}
    end
  end

  defp set_work_image(work, []), do: work

  defp set_work_image(work, [file_set_row | file_set_rows]) do
    if file_set_row
       |> Row.field_value(:work_image)
       |> Truth.true?() do
      file_set =
        file_set_row
        |> Row.field_value(:file_accession_number)
        |> FileSets.get_file_set_by_accession_number!()

      work |> Works.set_representative_image!(file_set)
    else
      set_work_image(work, file_set_rows)
    end
  end

  defp create_changeset_errors(changeset, file_set_rows) do
    with row <- file_set_rows |> List.first() do
      create_errors(
        row,
        "Create Work",
        errors_to_strings(changeset.errors)
      )
    end

    file_set_rows
    |> Enum.with_index()
    |> Enum.each(fn {row, index} ->
      with fs_changeset <- Enum.at(changeset.changes.file_sets, index) do
        create_errors(
          row,
          "CreateFileSet",
          errors_to_strings(fs_changeset.errors)
        )
      end
    end)

    nil
  end

  defp create_errors(ingest_sheet_row, action, []) do
    ActionStates.set_state!(ingest_sheet_row, action, "skipped")
  end

  defp create_errors(ingest_sheet_row, action, errors) do
    ActionStates.set_state!(ingest_sheet_row, action, "error", Enum.join(errors, "; "))
  end

  defp errors_to_strings(errors) do
    errors
    |> Enum.map(fn {field, {message, _opts}} ->
      [to_string(field), message] |> Enum.join(": ")
    end)
  end
end
