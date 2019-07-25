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
  end

  # Other scopes may use custom stacks.
  scope "/api" do
    pipe_through :api

    forward "/graphql", Absinthe.Plug, schema: MeadowWeb.Schema.Schema

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: MeadowWeb.Schema.Schema,
      socket: MeadowWeb.UserSocket
  end

  scope "/" do
    pipe_through :browser
    get "/login", MeadowWeb.AuthController, :login
    get "/auth/callback", MeadowWeb.AuthController, :callback

    get "/*path", MeadowWeb.PageController, :index
  end
end
