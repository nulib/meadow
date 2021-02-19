defmodule Meadow.Utils.Logging do
  @moduledoc "Logging utilities"

  @doc """
  Transparently change the logging level around a function

  Examples:
    iex> Meadow.Utils.Logging.with_log_level(:warn, fn ->
    ...>   8 * 8
    ...> end)
    64
  """
  def with_log_level(level, fun) do
    case Logger.level() do
      ^level -> fun.()
      _ -> temp_change_log_level(level, fun)
    end
  end

  defp temp_change_log_level(level, fun) do
    old_level = Logger.level()

    try do
      Logger.configure(level: level)
      fun.()
    after
      Logger.configure(level: old_level)
    end
  end
end
