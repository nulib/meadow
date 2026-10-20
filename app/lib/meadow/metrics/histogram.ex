defmodule Meadow.Metrics.Histogram do
  @moduledoc """
  Exponential bucketing for duration measurements.

  CloudWatch can only calculate percentiles from raw observations, so durations are
  published as `Values`/`Counts` arrays rather than as statistic sets. This module maps
  a millisecond measurement onto a bucket whose upper bound becomes the value published
  for every observation that landed in it.

  Buckets step by √2, so a percentile read off the published data overstates the true
  value by at most ~41%, and 50 buckets span 1ms through roughly 4.6 hours. Bucket
  granularity is free as far as CloudWatch billing goes — a `MetricDatum` carrying 50
  value/count pairs is one metric, the same as one carrying a single value — so the
  bucket count here is chosen for accuracy rather than cost.

  Because the bucket's upper bound is the representative value, `Sum`, `Average`, `Min`
  and `Max` read off these metrics are over-estimates bounded by the same ~41%. Exact
  aggregates would require publishing a statistic set alongside the histogram, which
  would double the billed metric count for little benefit at Meadow's volume.
  """

  # Index 0 holds non-positive measurements; 1..@max_index step by √2 from 1ms.
  @max_index 49

  @doc """
  The bucket index for a measurement in milliseconds.

  Non-positive measurements land in bucket 0. Anything above the top bucket's bound
  clamps to `#{@max_index}` rather than growing the table without limit.
  """
  @spec index(number()) :: non_neg_integer()
  def index(ms) when ms <= 0, do: 0

  def index(ms) do
    (:math.log2(ms) * 2)
    |> Float.ceil()
    |> trunc()
    |> Kernel.+(1)
    |> max(1)
    |> min(@max_index)
  end

  @doc """
  The upper bound, in milliseconds, of the bucket at `index`.

  This is the value published to CloudWatch for every observation in the bucket.
  """
  @spec bound(non_neg_integer()) :: non_neg_integer()
  def bound(0), do: 0

  def bound(index) when index > 0 and index <= @max_index do
    :math.pow(2, (index - 1) / 2) |> Float.round() |> trunc()
  end

  @doc "The highest bucket index this module will return."
  @spec max_index() :: pos_integer()
  def max_index, do: @max_index
end
