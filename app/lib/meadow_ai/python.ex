defmodule MeadowAI.Python do
  @moduledoc """
  Helper functions for initializing and managing the PythonX session
  with the Claude Code Python SDK.
  """
  alias Meadow.Config
  require Logger

  @doc """
  Reads a Python script from the priv/python/integration directory.
  """
  def pyread(file) do
    priv_dir = :code.priv_dir(:meadow) |> to_string()
    Path.join([priv_dir, "python", "integration", file]) |> File.read!()
  end

  @doc """
  Initializes the PythonX session and ensures python dependencies are installed.
  """
  def initialize_python_session(opts) do
    Logger.info("Initializing MetadataAgent")
    Application.ensure_all_started(:pythonx)

    # Initialize PythonX with Claude Code Python SDK
    # Use the on-disk pyproject but rewrite the local source path to an absolute path
    # so Pythonx.uv_init() can resolve it even if it runs from a temp directory.
    pyproject =
      pyread("pyproject.toml")
      |> String.replace("${PRIV_PATH}", :code.priv_dir(:meadow) |> to_string())

    force = Keyword.get(opts, :force, false)

    case Pythonx.uv_init(pyproject, force: force) do
      :ok ->
        initialize_python_environment()
        {:ok, %{initialized_at: DateTime.utc_now()}}

      _ ->
        {:error, :pythonx_init_failed}
    end
  rescue
    error in RuntimeError ->
      case error.message do
        "Python interpreter has already been initialized" -> {:ok, :already_initialized}
        _ -> {:error, {:initialization_error, error}}
      end

    error ->
      {:error, {:initialization_exception, error}}
  end

  defp initialize_python_environment do
    env = Config.ai(:pythonx_env, %{})

    Pythonx.eval(
      """
      import os
      env = {k.decode('utf-8'): v.decode('utf-8') for k, v in env.items()}
      os.environ.update(env)
      """,
      %{"env" => env}
    )
  end
end
