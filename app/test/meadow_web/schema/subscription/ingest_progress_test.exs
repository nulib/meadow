defmodule MeadowWeb.Schema.Subscription.IngestProgressTest do
  use Meadow.DataCase
  use Meadow.IngestCase
  use MeadowWeb.SubscriptionCase, async: true
  alias Meadow.Ingest.{Progress, Sheets, SheetsToWorks}
  alias Meadow.Pipeline
  alias Meadow.Pipeline.Actions.GenerateFileSetDigests
  alias Meadow.Pipeline.Dispatcher

  @work_count 2
  @file_set_count 8
  @action_count length(Dispatcher.all_progress_actions())
  @pct_factor 100 / (@file_set_count * @action_count - 1 + @work_count)

  load_gql(MeadowWeb.Schema, "test/gql/IngestProgress.gql")

  setup %{socket: socket, ingest_sheet: sheet} do
    start_supervised!({Progress, [interval: 100]})
    {:ok, sheet} = Sheets.update_ingest_sheet_status(sheet, "approved")
    groups = SheetsToWorks.initialize_progress(sheet)

    {:ok,
     ingest_sheet: sheet,
     work_rows: groups |> Enum.map(fn {_, [row | _]} -> row end),
     file_set_rows: groups |> Enum.flat_map(fn {_, rows} -> rows end),
     ref: subscribe_gql(socket, variables: %{"sheetId" => sheet.id, context: gql_context()})}
  end

  test "initiate subscription", %{ref: ref} do
    assert_reply ref, :ok, %{subscriptionId: _subscription_id}
  end

  test "receive data", %{ref: ref, ingest_sheet: sheet, work_rows: [first_row | _]} do
    assert_reply ref, :ok, %{subscriptionId: _subscription_id}

    Progress.update_entry(first_row, "CreateWork", "ok")
    Progress.update_entry(first_row, GenerateFileSetDigests, "ok")
    Progress.send_notifications()

    assert_push "subscription:data", %{
      result: %{data: %{"ingestProgress" => %{"percentComplete" => pct}}}
    }

    assert_in_delta(pct, @pct_factor * 2, 0.1)
    sheet = Sheets.get_ingest_sheet!(sheet.id)
    refute(sheet.status == "completed")
  end

  test "complete sheet", %{
    ref: ref,
    ingest_sheet: sheet,
    work_rows: work_rows,
    file_set_rows: file_set_rows
  } do
    assert_reply ref, :ok, %{subscriptionId: _subscription_id}

    work_rows
    |> Enum.each(fn row ->
      Progress.update_entry(row, "CreateWork", "ok")
    end)

    file_set_rows
    |> Enum.flat_map(fn row ->
      Pipeline.actions()
      |> Enum.map(fn action -> {row, action} end)
    end)
    |> Enum.each(fn {row, action} ->
      Progress.update_entry(row, action, "ok")
    end)

    Progress.send_notification(sheet.id)

    assert_push "subscription:data", %{
      result: %{data: %{"ingestProgress" => %{"percentComplete" => pct}}}
    }

    assert_in_delta(pct, 100, 0.10)

    assert Progress.pipeline_progress(sheet) |> Map.get(:percent_complete) == 100
  end
end
