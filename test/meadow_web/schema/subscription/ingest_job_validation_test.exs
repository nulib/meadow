defmodule MeadowWeb.Schema.Subscription.IngestJobValidationTest do
  use MeadowWeb.SubscriptionCase, async: true

  @subscription """
    subscription ($ingestJobId: ID!) {
      ingestJobValidationUpdate(ingestJobId: $ingestJobId){
        id
        object {
          content
          status
          errors
        }
      }
    }
  """

  test "ingest job validations can be subscribed to", %{socket: socket} do
    ingest_job = ingest_job_fixture()

    ref = push_doc(socket, @subscription, variables: %{"ingestJobId" => ingest_job.id})
    assert_reply ref, :ok, %{subscriptionId: subscription_id}
  end
end
