defmodule Meadow.Ingest.SheetsToWorks do
  @moduledoc """
  Functions to group IngestSheetRows into Works and FileSets
  and create the resulting database records
  """
  import Ecto.Query, warn: false
  alias Meadow.Config
  alias Meadow.Data.{AuditEntries, FileSets, Works}
  alias Meadow.Ingest.{Actions, IngestSheets}
  alias Meadow.Ingest.IngestSheets.{IngestSheet, IngestSheetRow}
  alias Meadow.Repo

  use Meadow.Constants

  def create_works_from_ingest_sheet(%IngestSheet{} = ingest_sheet) do
    ingest_sheet
    |> group_by_works()
    |> Enum.map(&ingest_work/1)
    |> IngestSheets.link_works_to_ingest_sheet(ingest_sheet)

    start_file_set_pipelines(ingest_sheet)
  end

  def group_by_works(%IngestSheet{} = ingest_sheet) do
    IngestSheets.list_ingest_sheet_rows(sheet: ingest_sheet)
    |> Enum.group_by(fn row -> row |> IngestSheetRow.field_value(:work_accession_number) end)
  end

  def start_file_set_pipelines(ingest_sheet) do
    from(s in IngestSheetRow,
      join: fs in FileSets.FileSet,
      on: s.file_set_accession_number == fs.accession_number,
      select: [s.row, fs.id],
      where: s.ingest_sheet_id == ^ingest_sheet.id
    )
    |> Repo.all()
    |> Enum.each(fn [row_num, file_set_id] ->
      Actions.IngestFileSet.send_message(
        %{file_set_id: file_set_id},
        %{context: "IngestSheet", ingest_sheet: ingest_sheet.id, ingest_sheet_row: row_num}
      )
    end)
  end

  defp ingest_work({accession_number, file_set_rows}) do
    ingest_bucket = Config.ingest_bucket()

    result =
      Repo.transaction(fn ->
        %{
          accession_number: accession_number,
          visibility: @default_visibility,
          work_type: "image",
          metadata: %{},
          file_sets:
            file_set_rows
            |> Enum.map(fn row ->
              file_path = IngestSheetRow.field_value(row, :filename)
              location = "s3://#{ingest_bucket}/#{file_path}"

              %{
                accession_number: row |> IngestSheetRow.field_value(:accession_number),
                role: row |> IngestSheetRow.field_value(:role),
                metadata: %{
                  description: row |> IngestSheetRow.field_value(:description),
                  location: location,
                  original_filename: Path.basename(file_path)
                }
              }
            end)
        }
        |> Works.create_work!()
      end)

    case result do
      {:ok, work} ->
        AuditEntries.add_entry!(work.id, "create", "ok")
        work

      {:error, reason} ->
        raise reason
    end
  end
end
