defmodule Meadow.TestLogHandler do
  @moduledoc """
  Suppress `invalid_catalog_name` errors while waiting for Ecto to create the database
  """
  def format(level, message, timestamp, metadata) do
    with text <- IO.iodata_to_binary(message) do
      if String.contains?(text, "invalid_catalog_name"),
        do: "",
        else: Logger.Formatter.format([:metadata, "[", :level, "] ", :message, "\n"], level, message, timestamp, metadata)
    end
  end
end
