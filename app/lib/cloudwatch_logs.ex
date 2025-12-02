defmodule CloudwatchLogs do
  @moduledoc """
  Provides functionality for the AWS Cloudwatch Logs API
  """

  alias ExAws.Operation.JSON, as: Operation

  @doc """
  Create a JSON request to create a log stream via the Cloudwatch Logs HTTP API
  """
  def create_log_stream(log_group_name, log_stream_name) do
    request(:post, "CreateLogStream", %{
      "logGroupName" => log_group_name,
      "logStreamName" => log_stream_name
    })
  end

  @doc """
  Create a JSON request to delete a log stream via the Cloudwatch Logs HTTP API
  """
  def delete_log_stream(log_group_name, log_stream_name) do
    request(:post, "DeleteLogStream", %{
      "logGroupName" => log_group_name,
      "logStreamName" => log_stream_name
    })
  end

  @doc """
  Create a JSON request to describe log streams via the Cloudwatch Logs HTTP API
  """
  def describe_log_streams(log_group_name, options \\ []) do
    data =
      Map.merge(
        %{
          "logGroupName" => log_group_name
        },
        camelize_options(options)
      )

    request(:post, "DescribeLogStreams", data)
  end

  @doc """
  Create a JSON request to get log events via the Cloudwatch Logs HTTP API
  """
  def get_log_events(log_group_name, log_stream_name, options \\ []) do
    data =
      Map.merge(
        %{
          "logGroupName" => log_group_name,
          "logStreamName" => log_stream_name
        },
        camelize_options(options)
      )

    request(:post, "GetLogEvents", data)
  end

  @doc """
  Create a JSON request to list log groups via the Cloudwatch Logs HTTP API
  """
  def list_log_groups(options \\ []) do
    request(:post, "DescribeLogGroups", camelize_options(options))
  end

  @doc """
  Create a JSON request to put log events via the Cloudwatch Logs HTTP API
  """
  def put_log_events(log_group_name, log_stream_name, log_events) do
    request(:post, "PutLogEvents", %{
      "logGroupName" => log_group_name,
      "logStreamName" => log_stream_name,
      "logEvents" => log_events
    })
  end

  defp camelize_options(options) do
    options
    |> Enum.map(fn {key, value} ->
      {Inflex.camelize(key, :lower), value}
    end)
    |> Enum.into(%{})
  end

  defp request(http_method, action, data) do
    Operation.new(:mediaconvert, %{
      data: data,
      headers: [
        {"x-amz-target", "Logs_20140328.#{action}"},
        {"content-type", "application/x-amz-json-1.1"}
      ],
      http_method: http_method,
      path: "/",
      service: :logs
    })
  end
end
