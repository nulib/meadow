defmodule Meadow.Utils.Lambda do
  @moduledoc """
  ### Description

  Module to assist with invoking nodeJS lambda code both locally and remotely.

  Example:

    # invoke the lambda function locally
    iex> invoke({:local, {"/path/to/my/lambda/script.js", "handler"}}, %{input: data})
    {:ok, "lambda_result"}

    # invoke the lambda function on AWS
    iex> invoke({:lambda, "myLambdaFunction"})
    {:ok, "lambda_result"}

  ### Notes on Lambdas

  In order to invoke lambda code locally, this module relies on a wrapper script that
  loads the lambda and handles communication with the parent Elixir process. Most nodeJS
  lambdas will work without alteration, but there are a few guidelines to consider.

  * Regular `console` methods (`log`, `debug`, `info`, `warn`, `error`) will send their
    messages back through the port and Elixir will log them at the appropriate level.
  * Other `console` methods (such as `trace`) that write directly to `stdout` and
    `stderr` may cause unexpected message warnings, but _shouldn't_ affect the overall
    functionality/reliability of the port interface.
  * Code that writes directly to `stdout` or `stderr` may cause unexpected results.
  """

  alias Meadow.Config

  require Logger

  @type local_lambda_config :: {:local, {script_path :: binary(), handler_function :: binary}}
  @type remote_lambda_config :: {:lambda, function_name :: binary()}
  @type lambda_config :: local_lambda_config() | remote_lambda_config()

  @buffer_size 512
  @timeout 120_000

  @doc """
  Invoke a Lambda function and return the JSON-decoded result.

  ## Parameters

    - config: The lambda to invoke. Can be one of:
      - Local NodeJS script: `{:local, {"/path/to/lambda/script.js", "exported_function_name"}}`
      - Remote Lambda function: `{:lambda, "function_name"}
    - payload: A map that will be sent to the Lambda handler as the `event`
    - timeout: The number of milliseconds to wait for a response (default: 30,000)
  """
  @spec invoke(config :: lambda_config(), payload :: map(), timeout :: number()) ::
          {:ok | :error, any()}
  def invoke(config, payload, timeout \\ @timeout) do
    case config do
      {:local, {script, handler}} -> invoke_local(script, handler, payload, timeout)
      {:lambda, lambda} -> invoke_lambda(lambda, payload, timeout)
    end
  end

  @doc """
  Make sure a particular Lambda function config isn't running in a port. Useful mainly
  for interactive debugging and iteration.
  """
  @spec close(config :: lambda_config()) :: :ok | :noop
  def close({:local, {script, handler}}) do
    case find_port(script, handler) do
      nil ->
        :noop

      port ->
        Logger.debug("Closing port #{inspect(port)}")
        Port.close(port)
        :ok
    end
  end

  def close(_), do: :noop

  @doc """
  Make sure a particular local Lambda function is pre-loaded and running in a port. Useful
  for local-only functions running in GenServers.
  """
  @spec init(config :: lambda_config()) :: {atom(), port()} | :noop
  def init({:local, {script, handler}}), do: find_or_create_port(script, handler)

  def init(_), do: :noop

  defp invoke_lambda(lambda, payload, timeout) do
    # coveralls-ignore-start
    Logger.metadata(lambda: lambda)

    case ExAws.Lambda.invoke(lambda, payload, %{})
         |> ExAws.request(http_opts: [recv_timeout: timeout], retries: [max_attempts: 1]) do
      {:ok, %{"errorType" => _, "errorMessage" => error_message, "trace" => trace}} ->
        Meadow.Error.report(%Meadow.LambdaError{message: error_message}, __MODULE__, [], %{
          lambda: lambda,
          payload: payload,
          trace: trace
        })

        {:error, error_message}

      {:error, {:http_error, status, %{body: message}}} = result ->
        Meadow.Error.report(%Meadow.LambdaError{message: message}, __MODULE__, [], %{
          http_status: status,
          lambda: lambda,
          payload: payload
        })

        result

      other ->
        other
    end

    # coveralls-ignore-stop
  end

  defp invoke_local(script, handler, payload, timeout) do
    with [script_file | [script_dir | _]] <- Path.split(script) |> Enum.reverse() do
      Logger.metadata(lambda: "#{script_dir}/#{script_file}:#{handler}")
    end

    with {_, port} <- find_or_create_port(script, handler),
         data <- Jason.encode!(payload) <> "\n" do
      send(port, {self(), {:command, data}})
      handle_output(port, timeout)
    end
  end

  defp handle_message(message) do
    case ~r"^\[(?<level>.+?)\] (?<message>.+)$" |> Regex.named_captures(message) do
      %{"level" => level, "message" => message} ->
        Logger.log(String.to_atom(level), message)

      _ ->
        Logger.warn("Unknown message received: #{message}")
    end
  end

  defp handle_buffer("[return] undefined") do
    Logger.warn("Received undefined response from lambda")
    {:ok, nil}
  end

  defp handle_buffer("[return] " <> value) do
    {:ok, Jason.decode!(value)}
  end

  defp handle_buffer("[fatal] " <> message) do
    Logger.error(message)
    {:error, message}
  end

  defp handle_buffer("[debug] ping"), do: :continue

  defp handle_buffer(message) do
    handle_message(message)
    :continue
  end

  defp handle_output(port, timeout, buffer \\ "") do
    receive do
      {^port, {:data, {:eol, data}}} ->
        case handle_buffer(buffer <> data) do
          :continue -> handle_output(port, timeout)
          other -> other
        end

      {^port, {:data, {:noeol, data}}} ->
        handle_output(port, timeout, buffer <> data)

      {^port, {:exit_status, status}} ->
        Logger.error("exit_status: #{status}")
        {:error, "exit_status: #{status}"}
    after
      timeout ->
        Logger.error("No response after #{timeout}ms")
        Port.close(port)
        {:error, "Timeout"}
    end
  end

  defp command_for(script, handler),
    do: [Config.priv_path("nodejs/lambda/index.js"), script, handler] |> Enum.join(" ")

  defp find_port(script, handler) do
    with command <- command_for(script, handler) do
      my_port? = fn p ->
        command ==
          Port.info(p)
          |> Keyword.get(:name)
          |> to_string()
      end

      Enum.find(Port.list(), my_port?)
    end
  end

  defp find_or_create_port(script, handler) do
    case find_port(script, handler) do
      nil -> spawn_port(script, handler)
      port -> {:existing, port}
    end
  end

  defp spawn_port(script, handler) do
    with script <- Path.expand(script) do
      if File.exists?(script) or File.exists?(script <> ".js") do
        with command <- command_for(script, handler) do
          Process.flag(:trap_exit, true)

          port =
            Port.open({:spawn, command}, [
              {:env, Config.aws_environment()},
              {:line, @buffer_size},
              :binary,
              :exit_status,
              :stderr_to_stdout
            ])

          Port.monitor(port)
          {:new, port}
        end
      else
        Logger.error("Failed to spawn #{script}: No such file")
        {:error, nil}
      end
    end
  end
end
