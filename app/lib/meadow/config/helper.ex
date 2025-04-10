defmodule Meadow.Config.Helper do
  @moduledoc """
  Helper functions for configuring Meadow's runtime environment. Interface compatible
  with Elixir's built-in `Config` module, but designed to be used at runtime.
  """

  def config(root_key, key, opts) do
    config(root_key, [{key, opts}])
  end

  def config(root_key, opts) do
    existing = Application.get_all_env(root_key)
    merged = Keyword.merge(existing, opts, &deep_merge/3)
    Application.put_all_env([{root_key, merged}])
  end

  defp deep_merge(_key, value1, value2) do
    if Keyword.keyword?(value1) and Keyword.keyword?(value2) do
      Keyword.merge(value1, value2, &deep_merge/3)
    else
      value2
    end
  end
end
