defmodule Meadow.TimeoutError, do: defexception([:message])
defmodule Meadow.LambdaError, do: defexception([:message])

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
        |> add_default_metadata(module),
      stacktrace: stacktrace
    )
  end

  def add_default_metadata(context, module \\ nil) do
    context
    |> Map.merge(%{
      meadow_version: Config.meadow_version(),
      notifier: module
    })
    |> add_tag("backend")
  end

  def add_tag(metadata, new_tag) do
    tag_list =
      with tags <- Map.get(metadata, :tags) do
        [tags, new_tag]
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.join(",")
      end

    Map.put(metadata, :tags, tag_list)
  end
end
