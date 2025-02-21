defmodule Meadow.Events.Arks do
  @moduledoc """
  Handles events related to ARKs.
  """

  alias Meadow.Arks
  alias Meadow.Data.Works

  use Meadow.Utils.Logging

  require Logger

  def handle_insert(%{name: name, new_record: record}) do
    with_log_metadata module: __MODULE__, id: record.id, name: name do
      Works.get_work(record.id) |> Arks.mint_ark()
    end
  end

  def handle_update(%{name: name, new_record: record, changes: _changes}) do
    with_log_metadata module: __MODULE__, id: record.id, name: name do
      case Works.get_work!(record.id) do
        nil -> :noop
        work -> update_ark_metadata(work)
      end
    end

  rescue
    Ecto.NoResultsError -> :noop
  end

  def handle_delete(%{name: name, old_record: record}) do
    with_log_metadata module: __MODULE__, id: record.id, name: name do
      Arks.work_deleted(record.id)
    end
  end

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
