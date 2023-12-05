defmodule MeadowWeb.Router do
  use MeadowWeb, :router
  use Honeybadger.Plug, plug_data: MeadowWeb.ErrorMetadata
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug(Plug.Logger)
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :secure_browser do
    plug(Plug.Logger)
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(MeadowWeb.Plugs.SetCurrentUser)
    plug(MeadowWeb.Plugs.RequireLogin)
  end

  pipeline :search do
    plug(:accepts, ["json"])

    plug(MeadowWeb.Plugs.SetCurrentUser)
    plug(MeadowWeb.Plugs.RequireLogin)
  end

  scope "/dashboard" do
    pipe_through(:secure_browser)

    live_dashboard("/",
      metrics: Meadow.Telemetry,
      ecto_repos: [Meadow.Repo],
      additional_pages: [broadway: {BroadwayDashboard, pipelines: Meadow.Pipeline.actions()}]
    )
  end

  scope "/_search" do
    pipe_through(:search)

    forward("/", MeadowWeb.Plugs.Search)
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(MeadowWeb.Plugs.SetCurrentUser)
  end

  # Other scopes may use custom stacks.
  scope "/api" do
    pipe_through(:api)

    post("/export/:file", MeadowWeb.ExportController, :export)
    post("/authority_records/bulk_create", MeadowWeb.AuthorityRecordsController, :bulk_create)
    post("/authority_records/:file", MeadowWeb.AuthorityRecordsController, :export)
    post("/create_shared_links/:file", MeadowWeb.SharedLinksController, :export)

    forward("/graphql", Absinthe.Plug, schema: MeadowWeb.Schema)

    forward("/graphiql", Absinthe.Plug.GraphiQL,
      schema: MeadowWeb.Schema,
      interface: :playground,
      socket: MeadowWeb.UserSocket
    )

    forward("/", Plug.Static,
      at: "/",
      from: {:meadow, "priv/static"},
      only: ["voyager"],
      headers: %{"content-type" => "text/html"}
    )
  end

  scope "/" do
    pipe_through(:browser)

    get("/auth/logout", MeadowWeb.AuthController, :logout)
    get("/auth/:provider", MeadowWeb.AuthController, :login)
    post("/auth/:provider", MeadowWeb.AuthController, :login)
    get("/auth/:provider/callback", MeadowWeb.AuthController, :callback)
    post("/auth/:provider/callback", MeadowWeb.AuthController, :callback)

    get("/*path", MeadowWeb.PageController, :index)
  end
end
