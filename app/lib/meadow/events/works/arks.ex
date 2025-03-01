defmodule Meadow.Events.Works.Arks do
  @moduledoc """
  Handles events related to ARKs.
  """

  alias Meadow.Arks
  alias Meadow.Data.Works

  use Meadow.Utils.Logging
  use WalEx.Event, name: Meadow

  require Logger

  on_event(:works, %{}, [{__MODULE__, :handle_event}], & &1)

  def handle_event(%{type: :insert, name: name, new_record: record}) do
    with_log_metadata module: __MODULE__, id: record.id, name: name do
      Works.get_work(record.id) |> Arks.mint_ark()
    end
  end

  def handle_event(%{type: :update, name: name, new_record: record, changes: changes}) do
    unless ark_changed(changes) do
      with_log_metadata module: __MODULE__, id: record.id, name: name do
        case Works.get_work!(record.id) do
          nil -> :noop
          work -> update_ark_metadata(work)
        end
      end
    end
  rescue
    Ecto.NoResultsError -> :noop
  end

  def handle_event(%{type: :delete, name: name, old_record: record}) do
    with_log_metadata module: __MODULE__, id: record.id, name: name do
      Arks.work_deleted(record.id)
    end
  end

  defp ark_changed(%{published: _}), do: false
  defp ark_changed(%{visibility: _}), do: false

  defp ark_changed(%{
         descriptive_metadata: %{
           old_value: %{"ark" => old_ark},
           new_value: %{"ark" => new_ark}
         }
       }) do
    old_ark != new_ark
  end

  defp ark_changed(_), do: false

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
