defmodule Meadow.StructuralMetadataListener do
  @moduledoc """
  Listens to INSERTS/UPDATES on Postgrex.Notifications topic "file_sets_changed" and writes
  structural metadata to S3
  """
  use Meadow.DatabaseNotification, tables: [:file_sets]
  use Meadow.Utils.Logging
  alias Meadow.Config
  alias Meadow.Data.FileSets
  alias Meadow.Pipeline.Actions.GeneratePosterImage
  alias Meadow.Utils.{AWS, Pairtree}
  require Logger

  @impl true
  def handle_notification(:file_sets, :delete, %{id: id}, state) do
    write_structural_metadata(%{id: id})
    {:noreply, state}
  end

  def handle_notification(:file_sets, _op, %{id: id}, state) do
    with_log_metadata module: __MODULE__, id: id do
      case FileSets.get_file_set(id) do
        nil -> :noop
        file_set -> write_structural_metadata(file_set)
      end
    end

    {:noreply, state}
  rescue
    Ecto.NoResultsError -> {:noreply, state}
  end

  defp write_structural_metadata(%{id: id, structural_metadata: %{type: "webvtt", value: vtt}})
       when is_binary(vtt) do
    Logger.info("Writing structural metadata for #{id}")

    ExAws.S3.put_object(Config.streaming_bucket(), vtt_location(id), vtt, content_type: "text/vtt")
    |> AWS.request()
  end

  defp write_structural_metadata(%{
         id: id,
         structural_metadata: %{type: "poster_offset", value: poster_offset}
       })
       when is_binary(poster_offset) do
    Logger.info("Creating poster for #{id} with offset #{poster_offset}")

    GeneratePosterImage.process(%{file_set_id: id}, %{offset: poster_offset})
  end

  defp write_structural_metadata(%{id: id}) do
    Logger.info("Deleting structural metadata for #{id}")

    ExAws.S3.delete_object(Config.streaming_bucket(), vtt_location(id))
    |> AWS.request()
  end

  defp vtt_location(id), do: Path.join(Pairtree.generate!(id), id <> ".vtt")
end
