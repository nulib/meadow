defmodule Meadow.Ingest.MockSubscription do
  @moduledoc """
  Fake Subscription - will count to 100- Delete
  """

  alias Meadow.Ingest.IngestSheets

  def async(id) do
    case Meadow.TaskRegistry |> Registry.lookup("mock" <> id) do
      [{pid, _}] ->
        {:running, pid}

      _ ->
        Task.start(fn ->
          Meadow.TaskRegistry |> Registry.register("mock" <> id, nil)
          count(id)
          set_complete(id)
        end)
    end
  end

  defp count(id) do
    Enum.each(0..10, fn x ->
      :timer.sleep(1000)

      Absinthe.Subscription.publish(
        MeadowWeb.Endpoint,
        %{count: x},
        mock_works_created_count: Enum.join(["mock_subscription", id], ":")
      )
    end)
  end

  defp set_complete(id) do
    id
    |> IngestSheets.get_ingest_sheet!()
    |> IngestSheets.update_ingest_sheet_status("completed")
  end
end
