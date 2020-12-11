defmodule MeadowWeb.Schema.Subscription.BatchStatusUpdateTest do
  use MeadowWeb.SubscriptionCase, async: true

  alias Meadow.Batches
  alias Meadow.Notifications

  load_gql(MeadowWeb.Schema, "test/gql/BatchStatusUpdate.gql")

  setup %{socket: socket} do
    batch = batch_fixture()

    {:ok,
     batch: batch,
     ref: subscribe_gql(socket, variables: %{"id" => batch.id, context: gql_context()})}
  end

  test "initiate subscription", %{ref: ref} do
    assert_reply ref, :ok, %{subscriptionId: _subscription_id}
  end

  test "receive batch status update data", %{ref: ref, batch: batch} do
    assert_reply ref, :ok, %{subscriptionId: _subscription_id}
    Batches.update_batch!(batch, %{status: "in_progress"})
    Notifications.batch(Batches.get_batch!(batch.id))

    assert_push "subscription:data", %{
      result: %{data: %{"batchStatusUpdate" => batch_status_update}}
    }

    assert get_in(batch_status_update, ["status"]) == "IN_PROGRESS"
  end
end
