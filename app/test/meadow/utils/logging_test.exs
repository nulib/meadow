defmodule Meadow.Utils.LoggingTest do
  use ExUnit.Case
  use Meadow.Utils.Logging

  import ExUnit.CaptureLog

  require Logger

  doctest Meadow.Utils.Logging

  test "log level is only changed within the passed fn" do
    logged =
      capture_log(fn ->
        assert Logger.level() == :info
        Logger.debug("This is a debug message")
      end)

    refute String.match?(logged, ~r/This is a debug message/)

    logged =
      capture_log([level: :debug], fn ->
        assert Logger.level() == :info

        result =
          with_log_level :debug do
            assert Logger.level() == :debug
            Logger.debug("This is a debug message")
            {:ok, :inner_fn_result}
          end

        assert result == {:ok, :inner_fn_result}
        assert Logger.level() == :info
      end)

    assert String.match?(logged, ~r/This is a debug message/)
  end
end
