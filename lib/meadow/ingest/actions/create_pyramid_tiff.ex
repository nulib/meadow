defmodule Meadow.Ingest.Actions.CreatePyramidTiff do
  @moduledoc "Create the pyramid tiff derivative for Image objects"

  alias Meadow.Config
  alias Meadow.Data.{AuditEntries, FileSets}
  alias Meadow.Utils.Pairtree
  alias Sequins.Pipeline.Action
  use Action

  @command "bin/fake_pyramid.js"
  @timeout 7_000

  def process(data, attrs),
    do: process(data, attrs, AuditEntries.ok?(data.file_set_id, __MODULE__))

  defp process(%{file_set_id: file_set_id}, _, true) do
    Logger.warn("Skipping #{__MODULE__} for #{file_set_id} – already complete")
    :ok
  end

  defp process(%{file_set_id: file_set_id}, _, _) do
    Logger.info("Beginning #{__MODULE__} for FileSet #{file_set_id}")
    file_set = FileSets.get_file_set!(file_set_id)

    port = find_or_create_port()

    case create_pyramid_tiff(file_set, port) do
      {:ok, _} ->
        AuditEntries.add_entry!(file_set, __MODULE__, "ok")
        :ok

      {:error, error} ->
        AuditEntries.add_entry!(file_set, __MODULE__, "error", error)
        {:error, error}
    end
  rescue
    err in RuntimeError -> {:error, err}
  end

  defp create_pyramid_tiff(file_set, port) do
    source = file_set.metadata.location
    target = pyramid_uri_for(file_set.id)
    input = Poison.encode!(%{source: source, target: target})

    send(port, {self(), {:command, input}})

    receive do
      {_port, {:data, "complete"}} ->
        Logger.info("complete")
        {:ok, "complete"}

      {_port, {:data, message}} ->
        Logger.error(message)
        {:error, message}

      {_port, {:exit_status, status}} ->
        Logger.error("exit_status: #{status}")
        {:error, "exit_status: #{status}"}
    after
      @timeout ->
        Logger.error("No response after 7s")
        {:error, "Timeout"}
    end
  end

  defp pyramid_uri_for(file_set_id) do
    dest_bucket = Config.pyramid_bucket()

    dest_key = Path.join(["/", Pairtree.generate_pyramid_path(file_set_id)])

    %URI{scheme: "s3", host: dest_bucket, path: dest_key} |> URI.to_string()
  end

  defp pyramid_port?(p) do
    @command ==
      Port.info(p)
      |> Keyword.get(:name)
      |> to_string()
  end

  defp find_or_create_port do
    case Enum.find(Port.list(), &pyramid_port?/1) do
      nil ->
        Logger.info("Spawning #{@command} in a new port")

        Process.flag(:trap_exit, true)

        port = Port.open({:spawn, @command}, [:binary, :exit_status])
        Port.monitor(port)
        port

      port ->
        Logger.debug("Using port #{inspect(port)} for #{@command}")
        port
    end
  end
end
