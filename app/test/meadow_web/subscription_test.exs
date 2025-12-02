defmodule MeadowWeb.SubscriptionTest do
  use MeadowWeb.SubscriptionCase, async: true
  alias Meadow.Notification
  alias Meadow.Ingest.Progress

  load_gql(MeadowWeb.Schema, "test/gql/IngestProgress.gql")

  setup %{socket: socket} do
    sheet = %{id: "test-sheet-id"}
    ref = subscribe_gql(socket, variables: %{"sheetId" => sheet.id}, context: gql_context())

    {:ok, %{ref: ref, sheet: sheet}}
  end

  test "initiate subscription", %{ref: ref} do
    assert_reply ref, :ok, %{subscriptionId: _subscription_id}, 5000
  end

  test "receive data", %{ref: ref, sheet: sheet} do
    assert_reply ref, :ok, %{subscriptionId: _subscription_id}, 5000
    pct = 42.5

    Notification.publish(
      %Progress{sheet_id: sheet.id, percent_complete: pct},
      ingest_progress: sheet.id
    )

    assert_push "subscription:data", %{
      result: %{data: %{"ingestProgress" => %{"percentComplete" => ^pct}}}
    }
  end
end
