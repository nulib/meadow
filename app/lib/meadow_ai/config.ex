defmodule MeadowAI.Config do
  @moduledoc """
  Configuration for MeadowAI components.
  """

  def get(key, default \\ nil) do
    Application.get_env(:meadow, MeadowAI, [])
    |> Keyword.get(key, default)
  end
end
