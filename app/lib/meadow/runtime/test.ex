defmodule Meadow.Runtime.Test do
  @moduledoc false

  import Config
  import Meadow.Runtime

  def configure! do
    config :meadow, :sitemaps,
      gzip: true,
      store: Sitemapper.S3Store,
      sitemap_url: "http://localhost:3333/",
      store_config: [bucket: prefix("uploads"), path: ""]
  end
end
