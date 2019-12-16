defmodule MeadowWeb.Schema.Subscription.SheetValidationTest do
  use MeadowWeb.SubscriptionCase, async: true

  @subscription """
    subscription ($sheetId: ID!) {
      ingestSheetValidationProgress(sheetId: $sheetId){
        states {
          state
          count
        }
        total
        percent_complete
      }
    }
  """

  test "ingest sheet validations can be subscribed to", %{socket: socket} do
    ingest_sheet = ingest_sheet_fixture()

    ref = push_doc(socket, @subscription, variables: %{"sheetId" => ingest_sheet.id})
    assert_reply ref, :ok, %{subscriptionId: subscription_id}
  end
end
