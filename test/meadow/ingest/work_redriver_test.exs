defmodule Meadow.Ingest.WorkRedriverTest do
  use Meadow.IngestCase
  alias Meadow.Ingest.{Progress, Rows, WorkRedriver}
  alias Meadow.Ingest.Schemas.Progress, as: ProgressSchema
  alias Meadow.Repo
  alias Meadow.Utils.MapList

  import ExUnit.CaptureLog

  @args [interval: 100]

  setup %{ingest_sheet: sheet} do
    worker = start_supervised!({WorkRedriver, @args})

    with rows <- Rows.list_ingest_sheet_rows(sheet: sheet) do
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, index} ->
        {row.id, MapList.get(row.fields, :header, :value, :role), rem(index, 4) == 0}
      end)
      |> Progress.initialize_entries()

      {:ok, %{worker: worker, ingest_sheet: sheet, rows: rows}}
    end
  end

  test "redrive_works/1", %{rows: [row | _rows]} do
    logged =
      capture_log(fn ->
        assert Logger.enabled?(self())

        Progress.get_entry(row, "CreateWork")
        |> ProgressSchema.changeset(%{
          status: "processing",
          updated_at: DateTime.add(DateTime.utc_now(), -80, :second)
        })
        |> Repo.update!()

        :timer.sleep(150)
      end)

    assert logged |> String.contains?("Redriving 1 works processing longer than 60 seconds")
  end
end
