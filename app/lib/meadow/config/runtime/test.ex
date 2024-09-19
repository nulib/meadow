defmodule Meadow.Config.Runtime.Test do
  @moduledoc """
  Load and apply Meadow's runtime configuration for the test environment
  """

  import Meadow.Config.Runtime

  def configure! do
    import Config

    config :meadow, Meadow.Search.Cluster,
      url: get_secret(:meadow, ["search", "cluster_endpoint"], "http://localhost:9200"),
      bulk_page_size: 3,
      bulk_wait_interval: 2,
      embedding_model_id: nil

    config :meadow, :sitemaps,
      gzip: true,
      store: Sitemapper.S3Store,
      base_url: "http://localhost:3333/",
      sitemap_url: "http://localhost:3333/",
      store_config: [bucket: prefix("uploads"), path: ""]
  end
end
