defmodule Meadow.ARKListener do
  @moduledoc """
  Listens to INSERTS/UPDATES on Postgrex.Notifications topic "works_changed" and writes
  updates ARK metadata
  """

  use Meadow.DatabaseNotification, tables: [:works]
  use Meadow.Utils.Logging
  alias Meadow.Data.Works
  require Logger

  @impl true
  def handle_notification(:works, :delete, %{id: _id}, state) do
    {:noreply, state}
  end

  def handle_notification(:works, :insert, %{id: _id}, state) do
    {:noreply, state}
  end

  def handle_notification(:works, _op, %{id: id}, state) do
    with_log_metadata module: __MODULE__, id: id do
      case Works.get_work!(id) do
        nil -> :noop
        work -> update_ark_metadata(work)
      end
    end

    {:noreply, state}
  rescue
    Ecto.NoResultsError -> {:noreply, state}
  end

  defp update_ark_metadata(work) do
    Logger.info(
      "Updating ARK metadata for work: #{work.id}, with ark: #{work.descriptive_metadata.ark}"
    )

    case Works.update_ark_metatdata(work) do
      {:ok, _result} ->
        :noop

      {:error, error_message} ->
        Logger.error(
          "Error updating ARK metadata for work: #{work.id}, with ark: #{work.descriptive_metadata.ark}. #{error_message}"
        )
    end
  end
end