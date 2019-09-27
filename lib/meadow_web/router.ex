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
    plug MeadowWeb.Plugs.SetCurrentUser
  end

  # Other scopes may use custom stacks.
  scope "/api" do
    pipe_through :api

    forward "/graphql", Absinthe.Plug, schema: MeadowWeb.Schema

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: MeadowWeb.Schema,
      socket: MeadowWeb.UserSocket

    forward "/", Plug.Static,
      at: "/",
      from: {:meadow, "priv/static"},
      only: ["voyager"],
      headers: %{"content-type" => "text/html"}
  end

  scope "/" do
    pipe_through :browser

    get "/auth/logout", MeadowWeb.AuthController, :logout
    get "/auth/:provider", MeadowWeb.AuthController, :login
    post "/auth/:provider", MeadowWeb.AuthController, :login
    get "/auth/:provider/callback", MeadowWeb.AuthController, :callback
    post "/auth/:provider/callback", MeadowWeb.AuthController, :callback

    get "/*path", MeadowWeb.PageController, :index
  end
end
