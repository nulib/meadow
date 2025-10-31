defmodule MeadowAI.MetadataAgent do
  use GenServer
  require Logger

  alias Meadow.Config
  alias Meadow.Utils.DCAPI
  alias MeadowAI.Config, as: AIConfig
  alias MeadowAI.IOHandler
  alias MeadowWeb.Router.Helpers, as: Routes

  import MeadowAI.Python

  @moduledoc """
  A GenServer that wraps PythonX functionality and provides AI-powered metadata generation tools.

  This agent integrates with the Claude Code Python SDK to provide:
  - Keyword generation from content and context via Claude using custom tools
  - Description generation for metadata purposes via Claude using custom tools
  - Session management and error recovery
  """

  @default_timeout 600_000

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Send a natural language query to Claude with optional context.

  Claude will intelligently choose which tools to use based on your request.

  ## Parameters
  - prompt: Natural language query
  - opts: Optional parameters including :context and :timeout

  ## Returns
  {:ok, response} | {:error, reason}
  """
  def query(prompt, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    GenServer.call(__MODULE__, {:query, prompt, opts}, timeout)
  end

  @doc """
  Gets the current status of the MetadataAgent.
  """
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @doc """
  Restarts the Python session (useful for recovery).
  """
  def restart_session do
    GenServer.call(__MODULE__, :restart_session, 60_000)
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    Logger.info("Starting MetadataAgent...")

    case initialize_python_session(opts) do
      {:ok, session_info} ->
        state = %{
          python_initialized: true,
          session_info: session_info,
          startup_time: DateTime.utc_now(),
          request_count: 0,
          failure_count: 0,
          last_failure: nil,
          circuit_breaker_state: :closed
        }

        Logger.info("MetadataAgent started successfully")
        {:ok, state}

      {:error, reason} ->
        Logger.error("Failed to initialize MetadataAgent: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_call({:query, prompt, opts}, _from, state) do
    timeout = div(Keyword.get(opts, :timeout, @default_timeout), 1000)

    {:ok, %{token: token}} =
      DCAPI.token(timeout,
        scopes: ["read:Public", "read:Published", "read:Private", "read:Unpublished"],
        is_superuser: true
      )

    opts =
      opts
      |> Keyword.put_new(
        :graphql_endpoint,
        Routes.page_url(MeadowWeb.Endpoint, :index, ["api", "graphql"])
      )
      |> Keyword.put_new(
        :mcp_url,
        Routes.page_url(MeadowWeb.Endpoint, :index, ["api", "mcp"])
      )
      |> Keyword.put_new(:graphql_auth_token, token)
      |> Keyword.put_new(
        :firewall_security_header,
        Application.get_env(:meadow, :firewall_security_header)
      )

    case state.python_initialized do
      true ->
        result = check_prompt_and_execute(prompt, opts)
        new_state = %{state | request_count: state.request_count + 1}
        {:reply, result, new_state}

      false ->
        Logger.warning("MetadataAgent: Python session not initialized, attempting restart...")

        case initialize_python_session([]) do
          {:ok, session_info} ->
            new_state = %{state | python_initialized: true, session_info: session_info}
            result = check_prompt_and_execute(prompt, opts)
            {:reply, result, %{new_state | request_count: new_state.request_count + 1}}

          {:error, reason} ->
            {:reply, {:error, {:session_unavailable, reason}}, state}
        end
    end
  end

  @impl true
  def handle_call(:status, _from, state) do
    status_info = %{
      python_initialized: state.python_initialized,
      startup_time: state.startup_time,
      request_count: state.request_count,
      uptime_seconds: DateTime.diff(DateTime.utc_now(), state.startup_time)
    }

    {:reply, {:ok, status_info}, state}
  end

  @impl true
  def handle_call(:restart_session, _from, state) do
    Logger.info("Restarting Python session...")

    case initialize_python_session([]) do
      {:ok, session_info} ->
        new_state = %{
          state
          | session_info: session_info,
            startup_time: DateTime.utc_now()
        }

        Logger.info("Python session restarted successfully")
        {:reply, :ok, new_state}

      {:error, reason} ->
        Logger.error("Failed to restart Python session: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_info(msg, state) do
    Logger.debug("MetadataAgent received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def terminate(reason, _state) do
    Logger.info("MetadataAgent terminating: #{inspect(reason)}")
    :ok
  end

  # Private Functions
  defp check_prompt_and_execute(prompt, opts) do
    if String.length(prompt) > 10_000 do
      {:error, {:input_too_large, "Prompt exceeds 10,000 characters"}}
    else
      execute_claude_query(prompt, opts)
    end
  end

  defp execute_claude_query(prompt, opts) do
    simple = AIConfig.get(:simple, false)
    if simple, do: Logger.warning("MetadataAgent running in simple mode")

    context =
      Keyword.get(opts, :context, %{})
      |> Map.put_new(:simple, simple)

    # Serialize context as JSON for Python
    context_json = Jason.encode!(context)

    # Ensure function exists and call it
    query_code = pyread("agent_integration.py")

    auth_header =
      case opts[:graphql_auth_token] do
        nil -> {}
        token -> {"Authorization", "Bearer #{token}"}
      end

    firewall_secrurity_header =
      case opts[:firewall_security_header] do
        [] -> {}
        header -> {header[:name], header[:value]}
      end

    headers =
      [auth_header, firewall_secrurity_header]
      |> Enum.into(%{})

    {:ok, io_handler} = IOHandler.open(id: Map.get(context, :plan_id))

    try do
      result =
        Pythonx.eval(
          query_code,
          %{
            "prompt" => prompt,
            "context_json" => context_json,
            "graphql_endpoint" => opts[:graphql_endpoint],
            "mcp_url" => opts[:mcp_url],
            "iiif_server_url" => Config.iiif_server_url(),
            "additional_headers" => headers
          },
          stdout_device: io_handler
        )

      case result do
        {response, _globals} -> {:ok, parse_claude_response(response)}
        error -> {:error, {:pythonx_eval_error, error}}
      end
    after
      IOHandler.close(io_handler)
    end
  rescue
    error ->
      log_python_error(error)
      {:error, {:query_execution_error, error}}
  end

  defp log_python_error(%Pythonx.Error{} = error) do
    pyex = fn code, data ->
      {output, _} = Pythonx.eval(code, %{"data" => data})
      Pythonx.decode(output)
    end

    [
      "Claude query execution error:",
      pyex.("str(data)", Map.get(error, :type)),
      pyex.("str(data)", Map.get(error, :value)),
      pyex.("import traceback; traceback.format_tb(data)", Map.get(error, :traceback))
    ]
    |> Enum.join("\n")
    |> Logger.error()
  end

  defp parse_claude_response(response) when is_binary(response) do
    String.trim(response)
  end

  defp parse_claude_response(%Pythonx.Object{} = response) do
    # Pythonx.decode returns the value directly, not wrapped in {:ok, result}
    decoded = Pythonx.decode(response)

    if is_binary(decoded) do
      String.trim(decoded)
    else
      to_string(decoded) |> String.trim()
    end
  rescue
    error ->
      Logger.warning("Failed to decode Pythonx.Object: #{inspect(error)}")
      # Fallback: extract from inspect output
      response
      |> inspect()
      |> String.replace(~r/#Pythonx\.Object<\s*"(.*)"\s*>/, "\\1")
      # Fix escaped newlines
      |> String.replace("\\n", "\n")
      |> String.trim()
  end

  defp parse_claude_response(response), do: to_string(response) |> String.trim()
end
