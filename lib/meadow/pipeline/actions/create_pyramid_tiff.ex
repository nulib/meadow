defmodule Meadow.Pipeline.Actions.CreatePyramidTiff do
  @moduledoc "Create the pyramid tiff derivative for Image objects"

  alias Meadow.Config
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Utils.Pairtree
  alias Sequins.Pipeline.Action
  use Action
  use Meadow.Pipeline.Actions.Common

  @timeout 300_000

  defp process(%{file_set_id: file_set_id}, _, _) do
    Logger.info("Beginning #{__MODULE__} for FileSet #{file_set_id}")
    file_set = FileSets.get_file_set!(file_set_id)
    source = file_set.metadata.location
    target = pyramid_uri_for(file_set.id)

    port = find_or_create_port()

    case create_pyramid_tiff(source, target, port) do
      {:ok, _} ->
        ActionStates.set_state!(file_set, __MODULE__, "ok")
        :ok

      {:error, error} ->
        ActionStates.set_state!(file_set, __MODULE__, "error", error)
        {:error, error}
    end
  rescue
    err in RuntimeError -> {:error, err}
  end

  defp create_pyramid_tiff("s3://" <> _ = source, target, port) do
    input = Poison.encode!(%{source: source, target: target})

    send(port, {self(), {:command, input}})
    handle_output(port)
  end

  defp create_pyramid_tiff(source, _target, _port) do
    Logger.error("Invalid s3://location: #{source}")
    {:error, "Invalid s3://location: #{source}"}
  end

  defp handle_message(message) do
    case ~r"^\[(?<level>.+?)\] (?<message>.+)$" |> Regex.named_captures(message) do
      %{"level" => level, "message" => message} ->
        Logger.log(String.to_atom(level), message)

      _ ->
        Logger.warn("Unknown message received: #{message}")
    end
  end

  defp handle_output(port) do
    receive do
      {^port, {:data, {:eol, "[ok]"}}} ->
        Logger.info("complete")
        {:ok, "complete"}

      {^port, {:data, {:eol, "[fatal] " <> message}}} ->
        Logger.error(message)
        {:error, message}

      {^port, {:data, {:eol, "[ping]"}}} ->
        handle_output(port)

      {^port, {:data, {:eol, message}}} ->
        handle_message(message)
        handle_output(port)

      {^port, {:exit_status, status}} ->
        Logger.error("exit_status: #{status}")
        {:error, "exit_status: #{status}"}
    after
      @timeout ->
        Logger.error("No response after #{@timeout}ms")
        {:error, "Timeout"}
    end
  end

  defp pyramid_uri_for(file_set_id) do
    dest_bucket = Config.pyramid_bucket()

    dest_key = Path.join(["/", Pairtree.pyramid_path(file_set_id)])

    %URI{scheme: "s3", host: dest_bucket, path: dest_key} |> URI.to_string()
  end

  defp find_or_create_port do
    command = Config.pyramid_processor()

    pyramid_port? = fn p ->
      command ==
        Port.info(p)
        |> Keyword.get(:name)
        |> to_string()
    end

    case Enum.find(Port.list(), pyramid_port?) do
      nil ->
        Logger.info("Spawning #{command} in a new port")
        Process.flag(:trap_exit, true)

        port =
          Port.open({:spawn, command}, [
            {:env, Config.aws_environment()},
            {:line, 512},
            :binary,
            :exit_status
          ])

        Port.monitor(port)
        port

      port ->
        Logger.debug("Using port #{inspect(port)} for #{command}")
        port
    end
  end
end
