defmodule Meadow.Metrics.Confirmation do
  @moduledoc """
  Checks if live CloudWatch metrics are enabled in a non-production environment,
  and requires confirmation via environment variable before publishing.
  """

  alias Meadow.Config
  alias Meadow.Metrics.CloudWatch
  import Meadow.Metrics.Aggregator, only: [publisher: 0, set_publisher: 1]

  require Logger

  @live_publisher CloudWatch
  @confirm_env "MEADOW_CLOUDWATCH_CONFIRM"

  @doc """
  Confirm live publishing if this node is about to do it outside production.
  """
  @spec confirm! :: :ok
  def confirm! do
    if needs_confirmation?() do
      preconfirmed?()
      |> do_confirm()
    else
      :ok
    end
  end

  @doc "Whether this node would publish live metrics outside production."
  @spec needs_confirmation?() :: boolean()
  def needs_confirmation? do
    publisher() == @live_publisher and Config.environment() not in [:prod, :test]
  end

  defp do_confirm(true) do
    Logger.warning("""
    Publishing live CloudWatch metrics to #{CloudWatch.namespace()} in the #{Config.environment()}
    environment (#{@confirm_env} is set)
    """)
    :ok
  end

  defp do_confirm(false) do
    Logger.error("""
    Meadow is configured to publish LIVE CloudWatch metrics. This writes
    billable custom metrics to the AWS account this node can reach.

      environment: #{Config.environment()}
      namespace:   #{CloudWatch.namespace()}

    Continuing with live metrics disabled. If you want to enable live metrics, set #{@confirm_env}=yes
    and restart the application.
    """)
    set_publisher(nil)
    :ok
  end

  @affirmative ["yes", "true", "1"]
  defp preconfirmed? do
    normalize(System.get_env(@confirm_env, "")) in @affirmative
  end


  defp normalize(value), do: value |> String.trim() |> String.downcase()
end
