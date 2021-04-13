defmodule Meadow.IIIF.ManifestListener do
  @moduledoc """
  Listens to INSERTS/UPDATES on Postgrex.Notifications topic "works_changed" and writes IIIF Manifests to S3
  """
  use Meadow.DatabaseNotification, tables: [:works]
  use Meadow.Utils.Logging
  require Logger

  alias Meadow.IIIF

  @impl true
  def handle_notification(:works, :delete, _key, state), do: {:noreply, state}

  def handle_notification(:works, _op, %{id: id}, state) do
    with_log_metadata module: __MODULE__, id: id do
      Logger.info("Writing manifest for #{id}")
      id |> IIIF.write_manifest()
    end

    {:noreply, state}
  rescue
    Ecto.NoResultsError -> {:noreply, state}
  end
end
