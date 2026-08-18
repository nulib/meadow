defmodule CloudwatchLogs do
  @moduledoc """
  Provides functionality for the AWS Cloudwatch Logs API
  """

  alias Meadow.AWS.Response

  @doc """
  Create a log stream
  """
  def create_log_stream(log_group_name, log_stream_name) do
    request(:create_log_stream, %{
      "logGroupName" => log_group_name,
      "logStreamName" => log_stream_name
    })
  end

  @doc """
  Delete a log stream
  """
  def delete_log_stream(log_group_name, log_stream_name) do
    request(:delete_log_stream, %{
      "logGroupName" => log_group_name,
      "logStreamName" => log_stream_name
    })
  end

  @doc """
  Describe the log streams in a log group
  """
  def describe_log_streams(log_group_name, options \\ []) do
    request(
      :describe_log_streams,
      Map.merge(%{"logGroupName" => log_group_name}, camelize_options(options))
    )
  end

  @doc """
  Get the events in a log stream
  """
  def get_log_events(log_group_name, log_stream_name, options \\ []) do
    request(
      :get_log_events,
      Map.merge(
        %{"logGroupName" => log_group_name, "logStreamName" => log_stream_name},
        camelize_options(options)
      )
    )
  end

  @doc """
  List the log groups
  """
  def list_log_groups(options \\ []) do
    request(:describe_log_groups, camelize_options(options))
  end

  @doc """
  Write events to a log stream
  """
  def put_log_events(log_group_name, log_stream_name, log_events) do
    request(:put_log_events, %{
      "logGroupName" => log_group_name,
      "logStreamName" => log_stream_name,
      "logEvents" => log_events
    })
  end

  defp camelize_options(options) do
    options
    |> Enum.map(fn {key, value} -> {Inflex.camelize(key, :lower), value} end)
    |> Enum.into(%{})
  end

  defp request(action, data) do
    Meadow.AWS.client(:logs)
    |> then(&apply(AWS.CloudWatchLogs, action, [&1, data]))
    |> Response.unwrap()
  end
end
