defmodule Meadow.Notifications do
  @moduledoc """
  functions for notifications to absinthe subscriptions
  """
  alias Meadow.Data.Schemas.Batch
  require Logger

  def batch({:ok, batch}),
    do: {:ok, batch(batch)}

  def batch(%Batch{} = batch) do
    Logger.info("Sending notifications for batch: #{batch.id} with status: #{batch.status}")

    Absinthe.Subscription.publish(
      MeadowWeb.Endpoint,
      batch,
      batch_status_update: "batch:" <> batch.id
    )

    Absinthe.Subscription.publish(
      MeadowWeb.Endpoint,
      batch,
      batches_status_updates: "batches"
    )

    batch
  end
end
