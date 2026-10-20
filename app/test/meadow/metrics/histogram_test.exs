defmodule Meadow.Metrics.HistogramTest do
  use ExUnit.Case, async: true

  alias Meadow.Metrics.Histogram

  describe "index/1" do
    test "non-positive measurements land in bucket 0" do
      assert Histogram.index(0) == 0
      assert Histogram.index(-5) == 0
    end

    test "is monotonic in the measurement" do
      indexes = Enum.map([1, 2, 10, 100, 1_000, 60_000, 3_600_000], &Histogram.index/1)
      assert indexes == Enum.sort(indexes)
      assert Enum.uniq(indexes) == indexes
    end

    test "clamps above the top bucket rather than growing without limit" do
      assert Histogram.index(:timer.hours(24)) == Histogram.max_index()
      assert Histogram.index(:timer.hours(24 * 365)) == Histogram.max_index()
    end
  end

  describe "bound/1" do
    test "bucket 0 bounds at 0" do
      assert Histogram.bound(0) == 0
    end

    test "the bound is an upper bound on everything in the bucket" do
      for ms <- [1, 2, 3, 7, 50, 999, 5_000, 90_000, 1_000_000] do
        assert Histogram.bound(Histogram.index(ms)) >= ms,
               "bucket for #{ms}ms bounds below the measurement"
      end
    end

    test "overstates by no more than the bucket width" do
      for ms <- [1, 3, 17, 450, 9_001, 250_000] do
        bound = Histogram.bound(Histogram.index(ms))
        assert bound <= ms * 1.5, "bucket for #{ms}ms bounds at #{bound}, wider than √2"
      end
    end

    test "stays inside the CloudWatch limit of 150 values per datum" do
      assert Histogram.max_index() + 1 <= 150
    end
  end
end
