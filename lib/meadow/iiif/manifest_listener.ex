defmodule Meadow.IIIF.ManifestListener do
  @moduledoc """
  Listens to INSERTS/UPDATES on Postgrex.Notifications topic "works_changed" and writes IIIF Manifests to S3
  """
  use Meadow.DatabaseNotification, tables: [:works]
  use Meadow.Utils.Logging
  require Logger

  alias Meadow.Data.Works
  alias Meadow.IIIF

  @impl true
  def handle_notification(:works, :delete, _key, state), do: {:noreply, state}

  def handle_notification(:works, _op, %{id: id}, state) do
    with_log_metadata module: __MODULE__, id: id do
      case Works.get_work!(id) do
        %{work_type: %{id: "IMAGE"}} ->
          Logger.info("Writing manifest for #{id}")
          id |> IIIF.write_manifest()
        _ -> Logger.info("Skipping manifest writing for non-image work #{id}")
      end

    end

    {:noreply, state}
  rescue
    Ecto.NoResultsError -> {:noreply, state}
  end
end
