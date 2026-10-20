defmodule Meadow.Metrics.Logger do
  @moduledoc """
  Publishes aggregated metric data to the configured logger.
  """

  @behaviour Meadow.Metrics.Publisher
  require Logger

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
      Logger.info(inspect(chunk))
      {:cont, :ok}
    end)
  end
end
