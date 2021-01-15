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
  @timeout 30_000

  @doc """
  Invoke a Lambda function and return the JSON-decoded result.

  ## Parameters

    - config: The lambda to invoke. Can be one of:
      - Local NodeJS script: `{:local, {"/path/to/lambda/script.js", "exported_function_name"}}`
      - Remote Lambda function: `{:lambda, "function_name"}
    - payload: A map that will be sent to the Lambda handler as the `event`
    - timeout: The number of milliseconds to wait for a response (default: 30,000)
  """
  @spec invoke(config :: lambda_config(), payload :: map(), timeout :: number()) :: any()
  def invoke(config, payload, timeout \\ @timeout) do
    case config do
      {:local, {script, handler}} -> invoke_local(script, handler, payload, timeout)
      {:lambda, lambda} -> invoke_lambda(lambda, payload, timeout)
    end
  end

  defp invoke_lambda(lambda, payload, _timeout) do
    # coveralls-ignore-start
    Logger.metadata(lambda: lambda)

    case ExAws.Lambda.invoke(lambda, payload, %{}) |> ExAws.request() do
      {:ok, %{"errorType" => _, "trace" => _} = error} -> {:error, error}
      other -> other
    end

    # coveralls-ignore-stop
  end

  defp invoke_local(script, handler, payload, timeout) do
    with [script_file | [script_dir | _]] <- Path.split(script) |> Enum.reverse() do
      Logger.metadata(lambda: "#{script_dir}/#{script_file}:#{handler}")
    end

    with port <- find_or_create_port(script, handler),
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

  defp handle_buffer("[return] " <> value) do
    {:ok, Jason.decode!(value)}
  end

  defp handle_buffer("[fatal] " <> message) do
    Logger.error(message)
    {:error, message}
  end

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
        Logger.debug("Buffering")
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

  defp find_or_create_port(script, handler) do
    command = [Config.priv_path("nodejs/lambda/index.js"), script, handler] |> Enum.join(" ")

    my_port? = fn p ->
      command ==
        Port.info(p)
        |> Keyword.get(:name)
        |> to_string()
    end

    case Enum.find(Port.list(), my_port?) do
      nil ->
        send(self(), "Spawning `#{command}` in a new port")
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
        port

      port ->
        send(self(), "Using port #{inspect(port)} for `#{command}`")
        port
    end
  end
end
