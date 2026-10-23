defmodule Meadow.Metrics.Confirmation do
  @moduledoc """
  Decides whether a node is allowed to publish live CloudWatch metrics.

  Production is. Anywhere else has to say so explicitly by setting
  `MEADOW_CLOUDWATCH_CONFIRM`, because `metrics[:publisher]` is one config line away from
  being the real thing and developer environments share an AWS account with staging.

  A node that is not allowed still runs the reporter, in dry-run mode: aggregation
  happens, batches are logged, nothing is sent and nothing is billed. Declining costs
  visibility into what *would* be sent, not the metrics themselves.

  This is a pure predicate, asked once by `Meadow.Metrics.reporter_options/0` when the
  supervisor builds its child spec. An earlier version prompted on stdin during
  `Application.start/2`; that does not work, because `mix phx.server` runs the VM with
  `-noshell`, where `standard_io` is output-only and `IO.gets/1` answers
  `{:error, :enotsup}` on a perfectly good terminal.
  """

  alias Meadow.Config

  @confirm_env "MEADOW_CLOUDWATCH_CONFIRM"
  @affirmative ~w(yes true 1)

  @doc """
  Whether this node may publish live metrics.
  """
  @spec live?() :: boolean()
  def live? do
    not needs_confirmation?() or preconfirmed?()
  end

  @doc """
  Whether this node has to be confirmed before publishing live.

  False in production, which is meant to publish, and in test, where the reporter does
  not run at all.
  """
  @spec needs_confirmation?() :: boolean()
  def needs_confirmation?, do: Config.environment() not in [:prod, :test]

  @doc """
  Why live publishing is or is not happening, as a line worth logging once at startup.
  """
  @spec reason() :: String.t()
  def reason do
    cond do
      not needs_confirmation?() -> "environment is #{Config.environment()}"
      preconfirmed?() -> "#{@confirm_env} is set"
      true -> "#{@confirm_env} is not set"
    end
  end

  @doc "The environment variable that confirms live publishing."
  @spec confirm_env() :: String.t()
  def confirm_env, do: @confirm_env

  defp preconfirmed? do
    System.get_env(@confirm_env, "")
    |> String.trim()
    |> String.downcase()
    |> then(&(&1 in @affirmative))
  end
end
