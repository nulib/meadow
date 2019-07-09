defmodule MeadowWeb.Router do
  use MeadowWeb, :router
  use Honeybadger.Plug

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug(OpenApiSpex.Plug.PutApiSpec, module: MeadowWeb.ApiSpec)
  end

  # Other scopes may use custom stacks.
  scope "/api" do
    pipe_through :api

    scope "/v1", MeadowWeb.Api.V1, as: :v1 do
      resources "/projects", ProjectController, except: [:new, :edit]
    end

    get "/openapi", OpenApiSpex.Plug.RenderSpec, []
  end

  scope "/" do
    pipe_through :browser
    get "/swaggerui", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi"
    get "/*path", MeadowWeb.PageController, :index
  end
end
