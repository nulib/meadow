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
  scope "/api", MeadowWeb do
    pipe_through :api
    resources "/languages", LanguageController
  end

  scope "/", MeadowWeb do
    pipe_through :browser

    get "/*path", PageController, :index
  end
end
