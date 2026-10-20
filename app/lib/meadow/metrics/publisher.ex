defmodule Meadow.Metrics.Publisher do
  @moduledoc """
  The contract `Meadow.Metrics.Aggregator` publishes through.

  Swappable via `config :meadow, metrics: [publisher: ...]` so tests can assert on what would
  go out without reaching AWS.
  """

  @callback put_metric_data(metric_data :: [map()], chunk_size :: pos_integer()) ::
              :ok | {:error, any()}
end
