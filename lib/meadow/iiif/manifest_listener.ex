defmodule Meadow.Iiif.ManifestListener do
  @moduledoc """
  Listens to INSERTS/UPDATES on Postgrex.Notifications topic "works_changed" and writes IIIF Manifests to S3
  """
  use GenServer
  require Logger
  alias Meadow.Config
  alias Meadow.Data.Works
  alias Meadow.IIIF
  alias Meadow.Iiif.Generator
  alias Meadow.Utils.Pairtree

  @topic "works_changed"

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(opts \\ []),
    do: GenServer.start_link(__MODULE__, opts)

  @impl true
  def init(opts) do
    case Meadow.Repo.listen(@topic) do
      {:ok, _pid, _ref} ->
        {:ok, opts}

      error ->
        {:stop, error}
    end
  end

  @impl true
  def handle_info({:notification, _pid, _ref, @topic, payload}, _state) do
    case Jason.decode(payload, keys: :atoms) do
      {:ok, data} ->
        id = data.record.id
        Logger.info("Writing manifest for #{id}")

        id |> IIIF.write_manifest()

        {:noreply, :event_handled}

      error ->
        {:stop, error, []}
    end
  end
end
