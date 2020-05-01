defmodule Meadow.Ingest.SheetsToWorks do
  @moduledoc """
  Functions to group Rows into Works and FileSets
  and create the resulting database records
  """
  import Ecto.Query, warn: false
  alias Meadow.Config
  alias Meadow.Data.{ActionStates, Works}
  alias Meadow.Data.Schemas.Work
  alias Meadow.Ingest.{Rows, SheetWorks, Status}
  alias Meadow.Ingest.Schemas.{Row, Sheet}
  alias Meadow.Pipeline

  use Meadow.Constants

  def create_works_from_ingest_sheet(%Sheet{} = ingest_sheet) do
    work_records = group_by_works(ingest_sheet)

    work_records
    |> Enum.map(fn work_record -> ingest_work(work_record) end)
    |> Enum.reject(fn work -> is_nil(work) end)
    |> SheetWorks.link_works_to_ingest_sheet(ingest_sheet)

    ingest_sheet
  end

  def group_by_works(%Sheet{} = ingest_sheet) do
    Rows.list_ingest_sheet_rows(sheet: ingest_sheet)
    |> Enum.group_by(fn row -> row |> Row.field_value(:work_accession_number) end)
  end

  def send_to_pipeline(ingest_sheet) do
    SheetWorks.get_file_sets_and_rows(ingest_sheet)
    |> Enum.each(fn %{row_num: row_num, file_set_id: file_set_id} ->
      Status.change(ingest_sheet.id, row_num, "pending")

      Pipeline.kickoff(file_set_id, %{
        context: "Sheet",
        ingest_sheet: ingest_sheet.id,
        ingest_sheet_row: row_num
      })
    end)

    ingest_sheet
  end

  defp ingest_work({accession_number, file_set_rows}) do
    ingest_bucket = Config.ingest_bucket()

    attrs = %{
      accession_number: accession_number,
      published: false,
      administrative_metadata: %{
        project: "",
        sheet: ""
      },
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
        end)
    }

    case Works.ensure_create_work(attrs) do
      {:ok, %Work{} = work} ->
        ActionStates.set_state!(work, "Create Work", "ok")
        work

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
