defmodule MeadowAI.Verification do
  @moduledoc """
  Module to verify the installation of the Claude Code Python SDK.
  """
  import MeadowAI.Python
  require Logger

  @doc """
  Verifies the Claude Code SDK installation and exits the BEAM process with
  an appropriate status code.
  """
  def verify_claude_and_exit(opts \\ []) do
    case verify_claude(opts) do
      {:ok, :claude_sdk_verified} ->
        Logger.info("Claude Code SDK installation verified successfully")
        exit(:normal)

      {:error, {type, reason}} ->
        Logger.error("MetadataAgent installation verification failed: #{type}: #{reason}")
        exit({:shutdown, 1})
    end
  end

  @doc """
  Verifies that the Claude Code Python SDK is properly installed and can be
  initialized within the PythonX session.

  ## Examples

      iex> MeadowAI.Verification.verify_claude()
      {:ok, :claude_sdk_verified}

      iex> MeadowAI.Verification.verify_claude()
      {:error,
        {"CLINotFoundError",
          "Claude Code not found. Install with:\n  npm install -g @anthropic-ai/claude-code\n\nIf already installed locally, try:\n  export PATH=\"$HOME/node_modules/.bin:$PATH\"\n\nOr provide the path via ClaudeAgentOptions:\n  ClaudeAgentOptions(cli_path='/path/to/claude')"}}
  """
  def verify_claude(opts \\ []) do
    case initialize_python_session(opts) do
      {:ok, _session_info} ->
        verify_claude_sdk(opts)

      {:error,
       {:initialization_error,
        %RuntimeError{message: "Python interpreter has already been initialized"}}} ->
        verify_claude_sdk(opts)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp verify_claude_sdk(opts) do
    script = pyread("agent_test.py")

    case Pythonx.eval(script, %{"cli_path" => opts[:cli_path]}) do
      {response, _globals} ->
        case Pythonx.decode(response) do
          %{"initialized" => true} ->
            {:ok, :claude_sdk_verified}

          %{"initialized" => false, "exception" => e, "reason" => msg} ->
            {:error, {e, msg}}
        end

      error ->
        {:error, {:claude_sdk_verification_failed, error}}
    end
  rescue
    err in Pythonx.Error ->
      {:error, {:claude_sdk_import_failed, err}}
  end
end
