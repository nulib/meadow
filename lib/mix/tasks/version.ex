defmodule Mix.Tasks.Meadow.Version do
  @moduledoc """
  Update mix.exs with the given semantic version string
  """
  use Mix.Task
  require Logger

  @shortdoc @moduledoc
  def run([]) do
    IO.puts("Usage: mix meadow.version MAJOR.MINOR.PATCH")
  end

  def run([version]) do
    if working_copy_dirty?(), do: raise("Cannot update version; working copy is not clean")

    version
    |> update_mix!()
    |> commit_mix!()
    |> tag!()

    Logger.info("Version updated to v#{version}")
  rescue
    err in RuntimeError -> Logger.error("Error: #{err.message}")
  end

  defp working_copy_dirty? do
    with {result, _} <- System.cmd("git", ["status", "--porcelain"]) do
      result
      |> String.split(~r/\n/)
      |> Enum.any?(&String.match?(&1, ~r/^ [MADRCU]/))
    end
  end

  defp update_mix!(version) do
    with mix_exs <-
           File.read!("mix.exs")
           |> String.replace(~r/@app_version "\d+.\d+.\d+.*"/, "@app_version #{version}") do
      File.write!("mix.exs", mix_exs)
      version
    end
  end

  defp commit_mix!(version) do
    git(["add", "mix.exs"])
    git(["commit", "-m", "Update version to #{version}"])
    version
  end

  defp tag!(version) do
    git(["tag", "v#{version}"])
  end

  defp git(args) do
    case System.cmd("git", args, stderr_to_stdout: true) do
      {_, 0} ->
        :noop

      {error, status} ->
        raise(
          "`git #{Enum.join(args, " ")}` failed with error #{error} and exit status #{status}"
        )
    end
  end
end
