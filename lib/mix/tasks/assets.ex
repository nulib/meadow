defmodule Mix.Tasks.Assets.IO do
  @moduledoc """
  IO functions for Assets mix tasks
  """
  require Logger

  def handle_output(port) do
    receive do
      {^port, {:data, data}} ->
        data
        |> String.trim()
        |> String.split(~r"[\r\n]+")
        |> Enum.each(&log/1)

        handle_output(port)

      {^port, {:exit_status, status}} ->
        status
    end
  end

  def run(cmd, path) do
    Logger.info("Running #{cmd} [#{path}]")

    port =
      Port.open({:spawn, cmd}, [
        {:cd, path},
        :stream,
        :binary,
        :exit_status,
        :hide,
        :use_stdio,
        :stderr_to_stdout
      ])

    handle_output(port)
  end

  defp log("warning " <> data), do: Logger.warn(data)
  defp log(data), do: Logger.info(data)
end

defmodule Mix.Tasks.Assets.Install do
  @moduledoc """
  Find and install JavaScript dependencies
  """
  use Mix.Task

  @shortdoc @moduledoc
  def run(_) do
    Path.wildcard("**/yarn.lock")
    |> Enum.reject(&String.starts_with?(&1, "_build"))
    |> Enum.reject(&String.contains?(&1, "node_modules"))
    |> Enum.map(&Path.dirname/1)
    |> Enum.each(fn path ->
      Mix.Tasks.Assets.IO.run("yarn install", path)
    end)
  end
end

defmodule Mix.Tasks.Assets.Build do
  @moduledoc """
  Builds static assets
  """
  use Mix.Task
  alias Mix.Tasks.Assets.Install

  @shortdoc @moduledoc
  def run(_) do
    Install.run(0)
    Mix.Tasks.Assets.IO.run("yarn deploy --production", "assets")
  end
end
