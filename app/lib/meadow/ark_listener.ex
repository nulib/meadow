defmodule Meadow.ArkListener do
  @moduledoc """
  Listens to INSERTS/UPDATES on Postgrex.Notifications topic "works_changed" and writes
  updates ARK metadata
  """

  use Meadow.DatabaseNotification, tables: [:works]
  use Meadow.Utils.Logging
  alias Meadow.Arks
  alias Meadow.Data.Works
  require Logger

  @impl true
  def handle_notification(:works, :delete, %{id: id}, state) do
    with_log_metadata module: __MODULE__, id: id do
      Logger.info("Received DELETE notification for ARK on work #{id}")
      Arks.work_deleted(id)
      {:noreply, state}
    end
  end

  def handle_notification(:works, :insert, %{id: id}, state) do
    with_log_metadata module: __MODULE__, id: id do
      Logger.info("Received INSERT notification for ARK on work #{id}")
      Works.get_work(id) |> Arks.mint_ark()
      {:noreply, state}
    end
  end

  def handle_notification(:works, op, %{id: id}, state) do
    with_log_metadata module: __MODULE__, id: id do
      Logger.info("Received #{String.upcase(to_string(op))} notification for ARK on work #{id}")

      case Works.get_work!(id) do
        nil -> :noop
        work -> update_ark_metadata(work)
      end
    end

    {:noreply, state}
  rescue
    Ecto.NoResultsError -> {:noreply, state}
  end

  def handle_notification(_, _, _, state), do: {:noreply, state}

  defp update_ark_metadata(work) do
    Logger.info(
      "Updating ARK metadata for work: #{work.id}, with ark: #{work.descriptive_metadata.ark}"
    )

    case Arks.update_ark_metadata(work) do
      :noop ->
        :noop

      {:ok, _result} ->
        :noop

      {:error, error_message} ->
        Logger.error(
          "Error updating ARK metadata for work: #{work.id}, with ark: #{work.descriptive_metadata.ark}. #{error_message}"
        )
    end
  end
end
