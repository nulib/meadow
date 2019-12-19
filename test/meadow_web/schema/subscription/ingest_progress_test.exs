defmodule MeadowWeb.Schema.Subscription.IngestProgressTest do
  use Meadow.IngestCase
  use MeadowWeb.SubscriptionCase, async: true
  alias Meadow.Data.ActionStates
  alias Meadow.Ingest.Actions.GenerateFileSetDigests
  alias Meadow.Ingest.{Pipeline, Sheets, Status}

  @file_set_count 7
  @action_count length(Pipeline.actions())
  @pct_factor 100 / (@file_set_count * @action_count)

  load_gql(MeadowWeb.Schema, "assets/js/gql/IngestProgress.gql")

  setup %{socket: socket, ingest_sheet: sheet} do
    sheet = create_works(sheet)
    file_sets = file_sets_for(sheet)

    file_sets
    |> Enum.each(fn file_set ->
      ActionStates.initialize_states(file_set, Pipeline.actions())
    end)

    {:ok,
     ingest_sheet: sheet,
     file_sets: file_sets,
     ref: subscribe_gql(socket, variables: %{"sheetId" => sheet.id, context: gql_context()})}
  end

  test "initiate subscription", %{ref: ref} do
    assert_reply ref, :ok, %{subscriptionId: subscription_id}
  end

  test "receive data", %{ref: ref, file_sets: file_sets, ingest_sheet: sheet} do
    assert_reply ref, :ok, %{subscriptionId: subscription_id}

    List.first(file_sets)
    |> ActionStates.set_state!(GenerateFileSetDigests, "ok")

    assert_push "subscription:data", %{
      result: %{data: %{"ingestProgress" => %{"percentComplete" => pct}}}
    }

    assert_in_delta(pct, @pct_factor, 0.01)
    sheet = Sheets.get_ingest_sheet!(sheet.id)
    refute(sheet.status == "completed")
  end

  test "complete sheet", %{ref: ref, file_sets: file_sets, ingest_sheet: sheet} do
    assert_reply ref, :ok, %{subscriptionId: subscription_id}

    file_sets
    |> Enum.with_index()
    |> Enum.each(fn {file_set, row} ->
      Status.change(sheet.id, row, "ok")
      ActionStates.initialize_states(file_set, Pipeline.actions(), "ok")
    end)

    Range.new(1, 28)
    |> Enum.each(fn i ->
      assert_push "subscription:data", %{
        result: %{data: %{"ingestProgress" => %{"percentComplete" => pct}}}
      }

      assert_in_delta(pct, i * @pct_factor, 0.01)
    end)

    sheet = Sheets.get_ingest_sheet!(sheet.id)
    assert(sheet.status == "completed")
  end
end
