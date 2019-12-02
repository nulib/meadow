defmodule MeadowWeb.Schema.Subscription.SheetValidationTest do
  use MeadowWeb.SubscriptionCase, async: true

  @subscription """
    subscription ($sheetId: ID!) {
      ingestSheetRowUpdate(sheetId: $sheetId){
        ingestSheet {
          id
          progress {
            states {
              state
              count
            }
            total
            percent_complete
          }
        }
        row
        fields {
          header
          value
        }
        state
        errors {
          field
          message
        }
      }
    }
  """

  test "ingest sheet validations can be subscribed to", %{socket: socket} do
    ingest_sheet = ingest_sheet_fixture()

    ref = push_doc(socket, @subscription, variables: %{"sheetId" => ingest_sheet.id})
    assert_reply ref, :ok, %{subscriptionId: subscription_id}
  end
end
