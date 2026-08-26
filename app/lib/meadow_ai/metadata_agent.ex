defmodule MeadowAI.MetadataAgent do
  use GenServer
  require Logger

  alias Meadow.Config
  alias Meadow.Utils.Lambda
  alias Meadow.Utils.DCAPI
  alias MeadowAI.Config, as: AIConfig

  @moduledoc """
  A GenServer that provides AI-powered metadata generation tools.

  This agent calls the MetadataAgent lambda to provide:
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

    Task.async(fn ->
      ref = make_ref()
      GenServer.cast(__MODULE__, {:query, prompt, opts, self(), ref})

      receive do
        {:query_result, ^ref, result} -> result
      after
        timeout -> {:error, :timeout}
      end
      |> case do
        {:ok, response} ->
          {:ok, response}

        {:error, reason} ->
          GenServer.call(__MODULE__, {:log_failure, reason})
          {:error, reason}
      end
    end)
    # Rely on the earlier timeout
    |> Task.await(:infinity)
  end

  @doc """
  Gets the current status of the MetadataAgent.
  """
  def status do
    GenServer.call(__MODULE__, :status)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    Logger.info("Starting MetadataAgent...")

    state = %{
      startup_time: DateTime.utc_now(),
      request_count: 0,
      failure_count: 0,
      last_failure: nil
    }

    Logger.info("MetadataAgent started successfully")
    {:ok, state}
  end

  @impl true
  def handle_cast({:query, prompt, opts, caller, ref}, state) do
    timeout = div(Keyword.get(opts, :timeout, @default_timeout), 1000)

    {:ok, %{token: token}} =
      DCAPI.token(timeout,
        scopes: ["read:Public", "read:Published", "read:Private", "read:Unpublished"],
        is_superuser: true
      )

    {mcp_path, opts} = Keyword.pop(opts, :mcp_path, "api/mcp")

    opts =
      opts
      |> Keyword.put_new(
        :mcp_url,
        MeadowWeb.RemoteAccess.url(mcp_path)
      )
      |> Keyword.put_new(:auth_token, token)
      |> Keyword.put_new(
        :firewall_security_header,
        Application.get_env(:meadow, :firewall_security_header)
      )

    Task.Supervisor.start_child(MeadowAI.MetadataAgent.TaskSupervisor, fn ->
      result =
        if Keyword.get(opts, :test, false) do
          :timer.sleep(500)
          {:ok, {%{"result" => "test"}, prompt, opts}}
        else
          check_prompt_and_execute(prompt, opts)
        end

      send(caller, {:query_result, ref, result})
    end)

    {:noreply, %{state | request_count: state.request_count + 1}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    status_info =
      Map.put(state, :uptime_seconds, DateTime.diff(DateTime.utc_now(), state.startup_time))

    {:reply, {:ok, status_info}, state}
  end

  @impl true
  def handle_call({:log_failure, _reason}, _from, state) do
    {:reply, :ok,
     %{state | failure_count: state.failure_count + 1, last_failure: DateTime.utc_now()}}
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

    headers =
      %{}
      |> put_auth_header(opts[:auth_token])
      |> put_firewall_security_header(opts[:firewall_security_header])

    Config.lambda_config(:metadataAgent)
    |> Lambda.invoke(
      %{
        "model" => AIConfig.get(:model),
        "prompt" => prompt,
        "context" => context,
        "mcp_url" => opts[:mcp_url],
        "additional_headers" => headers
      },
      timeout: 900_000,
      retries: 0
    )
    |> process_execution_result(opts)
  rescue
    error ->
      Logger.error(
        "Error executing Claude query: #{Exception.format(:error, error, __STACKTRACE__)}"
      )

      {:error, {:query_execution_error, error}}
  end

  defp put_auth_header(headers, nil), do: headers
  defp put_auth_header(headers, token), do: Map.put(headers, "Authorization", "Bearer #{token}")

  defp put_firewall_security_header(headers, header) when is_list(header) do
    case {header[:name], header[:value]} do
      {name, value} when is_binary(name) and is_binary(value) -> Map.put(headers, name, value)
      _ -> headers
    end
  end

  defp put_firewall_security_header(headers, _), do: headers

  # The metadataAgent lambda returns an API Gateway style `{statusCode, body}` map, which
  # `Meadow.Utils.Lambda.invoke/3` hands back JSON-decoded with its wire (string) keys.
  defp process_execution_result({:ok, %{"statusCode" => 200, "body" => body}}, opts) do
    case Jason.decode(body) do
      {:ok, decoded} ->
        log_metrics(decoded, Keyword.get(opts, :metadata, %{}))
        {:ok, Map.take(decoded, ["result", "model", "total_cost_usd"])}

      error ->
        {:error, {:invalid_response, error}}
    end
  end

  defp process_execution_result({:ok, %{"statusCode" => status_code, "body" => body}}, _opts) do
    Logger.error("Lambda execution error: Status #{status_code}, Body: #{body}")
    {:error, {:lambda_invocation_failed, status_code, body}}
  end

  defp process_execution_result({:ok, %{"errorMessage" => error_message}}, _opts) do
    Logger.error("Lambda execution error: #{error_message}")
    {:error, {:lambda_invocation_failed, error_message}}
  end

  defp process_execution_result({:error, reason}, _opts) do
    Logger.error("Lambda invocation failed: #{inspect(reason)}")
    {:error, {:lambda_invocation_failed, reason}}
  end

  defp process_execution_result(result, _opts) do
    Logger.error("Lambda invocation returned unknown result: #{inspect(result)}")
    {:error, {:lambda_invocation_failed, result}}
  end

  defp log_metrics(message, metadata) do
    config = AIConfig.get(:metrics_log)

    CloudwatchLogs.create_log_stream(config[:group], config[:stream])

    cloudwatch_message =
      message
      |> Map.put("metadata", metadata)
      |> Map.put("model", AIConfig.get(:model))

    CloudwatchLogs.put_log_events(config[:group], config[:stream], [
      %{
        "timestamp" => DateTime.utc_now() |> DateTime.to_unix(:millisecond),
        "message" => Jason.encode!(cloudwatch_message)
      }
    ])
  end
end
