defmodule MeadowWeb.ErrorMetadata do
  @moduledoc """
  Honeybadger plug_data module to inject the meadow version into Honeybadger's context
  """
  alias Honeybadger.PlugData
  alias Meadow.Config

  def metadata(conn, module) do
    PlugData.metadata(conn, module)
    |> Map.merge(%{meadow_version: Config.meadow_version()})
  end
end
