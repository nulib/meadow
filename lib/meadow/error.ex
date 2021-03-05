defmodule Meadow.Error do
  @moduledoc """
  Convenience module for error reporting via Honeybadger
  """
  alias Meadow.Config

  def report(exception, module, stacktrace, additional_context \\ %{}) do
    Honeybadger.notify(exception,
      metadata:
        Honeybadger.context()
        |> Map.merge(additional_context)
        |> Map.merge(%{
          meadow_version: Config.meadow_version(),
          notifier: module
        }),
      stacktrace: stacktrace
    )
  end
end
