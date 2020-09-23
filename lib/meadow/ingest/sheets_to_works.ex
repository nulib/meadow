defmodule Meadow.Ingest.SheetsToWorks do
  @moduledoc """
  Functions to group Rows into Works and FileSets
  and create the resulting database records
  """
  import Ecto.Query, warn: false
  alias Meadow.Config
  alias Meadow.Data.{ActionStates, Works}
  alias Meadow.Data.Schemas.{FileSet, Work}
  alias Meadow.Ingest.{Progress, Rows, Status}
  alias Meadow.Ingest.Schemas.{Row, Sheet}
  alias Meadow.Pipeline

  use Meadow.Constants

  def create_works_from_ingest_sheet(%Sheet{} = ingest_sheet) do
    ingest_sheet
    |> initialize_progress()
    |> Enum.each(fn work_record -> ingest_work(work_record, ingest_sheet) end)

    ingest_sheet
  end

  def group_by_works(%Sheet{} = ingest_sheet) do
    Rows.list_ingest_sheet_rows(sheet: ingest_sheet)
    |> Enum.group_by(fn row -> row |> Row.field_value(:work_accession_number) end)
  end

  def send_work_to_pipeline(ingest_sheet, work, file_set_rows) do
    work.file_sets
    |> Enum.zip(file_set_rows)
    |> Enum.each(fn {%FileSet{id: file_set_id}, %Row{row: row_num}} ->
      Status.change(ingest_sheet.id, row_num, "pending")

      Pipeline.kickoff(file_set_id, %{
        context: "Sheet",
        ingest_sheet: ingest_sheet.id,
        ingest_sheet_row: row_num
      })
    end)

    work
  end

  def initialize_progress(ingest_sheet) do
    with groups <- group_by_works(ingest_sheet) do
      groups
      |> Enum.flat_map(fn {_, rows} ->
        rows
        |> Enum.with_index()
        |> Enum.map(fn {row, index} -> {row.id, index == 0} end)
      end)
      |> Progress.initialize_entries()

      groups
    end
  end

  defp ingest_work({accession_number, file_set_rows}, ingest_sheet) do
    ingest_bucket = Config.ingest_bucket()

    attrs = %{
      accession_number: accession_number,
      file_sets:
        file_set_rows
        |> Enum.map(fn row ->
          file_path = Row.field_value(row, :filename)
          location = "s3://#{ingest_bucket}/#{file_path}"

          %{
            accession_number: row |> Row.field_value(:accession_number),
            role: row |> Row.field_value(:role),
            metadata: %{
              description: row |> Row.field_value(:description),
              location: location,
              original_filename: Path.basename(file_path),
              label: Path.basename(file_path)
            }
          }
        end),
      ingest_sheet_id: ingest_sheet.id,
      published: false,
      visibility: %{id: "RESTRICTED", scheme: "visibility"},
      work_type: %{id: "IMAGE", scheme: "work_type"}
    }

    case Works.ensure_create_work(attrs) do
      {:ok, %Work{} = work} ->
        Progress.update_entry(List.first(file_set_rows), "CreateWork", "ok")
        ActionStates.set_state!(work, "Create Work", "ok")
        send_work_to_pipeline(ingest_sheet, work, file_set_rows)

      {:error, changeset} ->
        create_changeset_errors(changeset, file_set_rows)
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
