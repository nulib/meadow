defmodule Meadow.IngestCase do
  use ExUnit.CaseTemplate

  @moduledoc """
  This module sets up an ingest sheet and resulting works for testing
  queries and subscriptions related to ingest progress, and provides
  convenience functions for manipulating their progress.
  """

  alias Meadow.Repo
  alias Meadow.Ingest.{IngestSheets, SheetsToWorks}
  import Meadow.TestHelpers

  @fixture "test/fixtures/ingest_sheet.csv"

  using do
    quote do
      alias Meadow.Ingest.IngestSheets
      import Meadow.IngestCase

      def create_works(sheet) do
        sheet
        |> SheetsToWorks.create_works_from_ingest_sheet()
        |> Repo.preload(:works)
      end
    end
  end

  setup tags do
    :ok = sandbox_mode(tags)
    sheet = ingest_sheet_rows_fixture(@fixture)

    sheet
    |> IngestSheets.change_ingest_sheet_state!(%{file: "pass", rows: "pass", overall: "pass"})
    |> Repo.preload(:ingest_sheet_rows)
    |> Map.get(:ingest_sheet_rows)
    |> Enum.each(fn
      row -> IngestSheets.change_ingest_sheet_row_state(row, "pass")
    end)

    {:ok, ingest_sheet: sheet}
  end

  def file_sets_for(sheet) do
    sheet
    |> Repo.preload(:works)
    |> Map.get(:works)
    |> Repo.preload(:file_sets)
    |> Enum.reduce([], fn work, acc ->
      acc ++ work.file_sets
    end)
  end
end
