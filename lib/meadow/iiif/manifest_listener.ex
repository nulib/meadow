defmodule Meadow.IIIF.ManifestListener do
  @moduledoc """
  Listens to INSERTS/UPDATES on Postgrex.Notifications topic "works_changed" and writes IIIF Manifests to S3
  """
  use Meadow.DatabaseNotification, tables: [:works]
  require Logger

  alias Meadow.IIIF

  @impl true
  def handle_notification(:works, :delete, _key, state), do: {:noreply, state}

  def handle_notification(:works, _op, %{id: id}, state) do
    Logger.info("Writing manifest for #{id}")
    id |> IIIF.write_manifest()
    {:noreply, state}
  rescue
    Ecto.NoResultsError -> {:noreply, state}
  end
end
