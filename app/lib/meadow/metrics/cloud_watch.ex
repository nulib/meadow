defmodule Meadow.Metrics.CloudWatch do
  @moduledoc """
  Publishes aggregated metric data to CloudWatch via `PutMetricData`.

  aws-elixir talks to CloudWatch over the JSON protocol (CloudWatch carries the
  `awsQueryCompatible` trait), so `Values`/`Counts` arrays nest naturally in the request
  body rather than needing the flattening the older query protocol required.

  The client is built for `:cloudwatch`, which is the key the `:services` endpoint
  overrides use, not the `monitoring` endpoint prefix AWS itself uses for this service.
  Asking for the wrong one silently falls through to the shared endpoint config and sends
  test traffic to real AWS.
  """

  @behaviour Meadow.Metrics.Publisher

  alias Meadow.AWS.Response

  @doc """
  Publish `metric_data` in chunks of at most `chunk_size` items.

  Returns `:ok` only if every chunk succeeded; the first failure short-circuits and is
  returned as-is, since a partial publish is not worth unwinding — the next flush will
  carry fresh measurements anyway.
  """
  @impl Meadow.Metrics.Publisher
  def put_metric_data(metric_data, chunk_size) do
    metric_data
    |> Enum.chunk_every(chunk_size)
    |> Enum.reduce_while(:ok, fn chunk, _acc ->
      case put_chunk(chunk) do
        {:ok, _} -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  @doc """
  The CloudWatch namespace metrics are published under.
  """
  @base_namespace "Meadow"
  @deployed_tenants ~w(meadow staging)

  def namespace do
    Application.get_env(:meadow, :cloudwatch_namespace) || namespace_for(tenant())
  end

  defp namespace_for(tenant) when tenant in [nil, ""], do: @base_namespace

  defp namespace_for(tenant) do
    if tenant in deployed_tenants(),
      do: @base_namespace,
      else: "#{@base_namespace}/#{tenant}"
  end

  defp deployed_tenants,
    do: Application.get_env(:meadow, :cloudwatch_deployed_tenants, @deployed_tenants)

  defp tenant, do: Application.get_env(:meadow, :environment_prefix)

  defp put_chunk(chunk) do
    Meadow.AWS.client(:cloudwatch)
    |> AWS.CloudWatch.put_metric_data(%{
      "Namespace" => namespace(),
      "MetricData" => chunk
    })
    |> Response.unwrap()
  end
end
