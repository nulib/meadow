defmodule Meadow.IIIF.ManifestListener do
  @moduledoc """
  Listens to INSERTS/UPDATES on Postgrex.Notifications topic "works_changed" and writes IIIF Manifests to S3
  """

  alias Meadow.{BackgroundTask, IIIF}
  use BackgroundTask, periodic: false
  require Logger

  @topic :works_changed

  @impl BackgroundTask
  def before_init(_) do
    Meadow.Repo.listen(to_string(@topic))
    :ok
  end

  @impl BackgroundTask
  def handle_notification(@topic, payload, state) do
    case Jason.decode(payload, keys: :atoms) do
      {:ok, data} ->
        id = data.record.id
        Logger.info("Writing manifest for #{id}")

        id |> IIIF.write_manifest()

      _ ->
        Logger.warn("Unknown payload: #{payload}")
    end

    {:noreply, state}
  end
end
