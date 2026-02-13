defmodule MeadowAI.MetadataAgent do
  use GenServer
  require Logger

  alias Meadow.Config
  alias Meadow.Utils.Lambda
  alias Meadow.Utils.DCAPI
  alias MeadowAI.Config, as: AIConfig
  alias MeadowWeb.Router.Helpers, as: Routes

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
    |> Task.await(:infinity) # Rely on the earlier timeout
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

    Task.Supervisor.start_child(MeadowAI.MetadataAgent.TaskSupervisor, fn ->
      result = if Keyword.get(opts, :test, false) do
        :timer.sleep(500)
        {:ok, {"test", prompt, opts}}
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

    Config.lambda_config(:metadataAgent)
    |> Lambda.invoke(
      %{
        "model" => AIConfig.get(:model),
        "prompt" => prompt,
        "context" => context,
        "graphql_endpoint" => opts[:graphql_endpoint],
        "mcp_url" => opts[:mcp_url],
        "iiif_server_url" => Config.iiif_server_url(),
        "additional_headers" => headers
      },
      900_000
    )
    |> process_execution_result()
  rescue
    error ->
      Logger.error("Error executing Claude query: #{Exception.message(error)}")
      {:error, {:query_execution_error, error}}
  end

  defp process_execution_result({:ok, %{"statusCode" => 200, "body" => body}}) do
    case Jason.decode(body) do
      {:ok, decoded} ->
        log_metrics(decoded)
        {:ok, decoded["result"]}

      error ->
        {:error, {:invalid_response, error}}
    end
  end

  defp process_execution_result({:ok, %{"statusCode" => status_code, "body" => body}}) do
    Logger.error("Lambda execution error: Status #{status_code}, Body: #{body}")
    {:error, {:lambda_eval_error, status_code, body}}
  end

  defp process_execution_result(result) do
    Logger.error("Lambda invocation returned unknown result: #{inspect(result)}")
    {:error, {:lambda_invocation_failed, result}}
  end

  defp log_metrics(message) do
    config = AIConfig.get(:metrics_log)

    CloudwatchLogs.create_log_stream(config[:group], config[:stream])
    |> ExAws.request()

    CloudwatchLogs.put_log_events(config[:group], config[:stream], [
      %{
        "timestamp" => DateTime.utc_now() |> DateTime.to_unix(:millisecond),
        "message" => Jason.encode!(Map.put(message, "model", AIConfig.get(:model)))
      }
    ])
    |> ExAws.request()
  end
end
