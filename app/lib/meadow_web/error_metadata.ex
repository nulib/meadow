defmodule MeadowWeb.ErrorMetadata do
  @moduledoc """
  Honeybadger plug_data module to inject the meadow version into Honeybadger's context
  """
  alias Honeybadger.PlugData

  def metadata(conn, module) do
    PlugData.metadata(conn, module)
    |> Meadow.Error.add_default_metadata()
  end
end
