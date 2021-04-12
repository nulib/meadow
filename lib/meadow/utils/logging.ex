defmodule Meadow.Utils.Logging do
  @moduledoc "Logging utilities"

  defmacro __using__(_) do
    quote do
      require Meadow.Utils.Logging
      import Meadow.Utils.Logging
    end
  end

  @doc """
  Transparently change the logging level around a block

  Examples:
    iex> Meadow.Utils.Logging.with_log_level :warn do
    ...>   8 * 8
    ...> end
    64
  """
  defmacro with_log_level(level, do: block) do
    quote do
      case Logger.level() do
        unquote(level) ->
          unquote(block)

        _ ->
          with old_level <- Logger.level() do
            try do
              Logger.configure(level: unquote(level))
              unquote(block)
            after
              Logger.configure(level: old_level)
            end
          end
      end
    end
  end

  @doc """
  Transparently change the logging metadata around a block

  Examples:
    iex> Meadow.Utils.Logging.with_log_metadata module: "math" do
    ...>   8 * 8
    ...> end
    64
  """
  defmacro with_log_metadata(metadata, do: block) do
    quote do
      old_metadata =
        unquote(metadata)
        |> Enum.map(fn {key, _} -> {key, nil} end)
        |> Keyword.merge(Logger.metadata())

      try do
        Logger.metadata(unquote(metadata))
        unquote(block)
      after
        Logger.metadata(old_metadata)
      end
    end
  end
end
