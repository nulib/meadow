defmodule MeadowWeb.ApiSpec do
  @moduledoc """
  populates an OpenApiSpex.OpenApi struct for MeadowWeb

  """
  alias OpenApiSpex.{Info, OpenApi, Paths}
  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      info: %Info{
        title: "Meadow",
        version: "1.0"
      },
      paths: Paths.from_router(MeadowWeb.Router)
    }
    # discover request/response schemas from path specs
    |> OpenApiSpex.resolve_schema_modules()
  end
end
