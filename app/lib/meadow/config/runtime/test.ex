defmodule Meadow.Config.Runtime.Test do
  @moduledoc """
  Load and apply Meadow's runtime configuration for the test environment
  """

  import Meadow.Config.Secrets

  def configure! do
    import Meadow.Config.Helper

    # We don't run a server during test. If one is required,
    # you can enable the server option below.
    config :meadow, MeadowWeb.Endpoint,
      http: [port: 4002],
      server: false

    config :meadow,
      index_interval: 1234,
      mediaconvert_client: MediaConvert.Mock

    # Configures lambda scripts
    config :meadow, :lambda,
      digester: {:local, {Path.expand("../lambdas/digester/index.js"), "handler"}},
      exif: {:local, {Path.expand("../lambdas/exif/index.js"), "handler"}},
      frame_extractor: {:local, {Path.expand("../lambdas/frame-extractor/index.js"), "handler"}},
      mediainfo: {:local, {Path.expand("../lambdas/mediainfo/index.js"), "handler"}},
      mime_type: {:local, {Path.expand("../lambdas/mime-type/index.js"), "handler"}},
      tiff: {:local, {Path.expand("../lambdas/pyramid-tiff/index.js"), "handler"}}

    config :meadow,
      checksum_notification: %{
        arn: "arn:aws:lambda:us-east-1:000000000000:function:digest-tag",
        buckets: ["test-ingest", "test-upload"]
      },
      required_checksum_tags: ["computed-md5"],
      checksum_wait_timeout: 15_000

    config :meadow, :elasticsearch_retry,
      interval: 100,
      max_retries: 3

    config :authoritex, authorities: [Authoritex.Mock, NUL.Authority]

    config :meadow, Meadow.Repo,
      show_sensitive_data_on_connection_error: true,
      timeout: 60_000,
      connect_timeout: 60_000,
      handshake_timeout: 60_000,
      pool: Ecto.Adapters.SQL.Sandbox,
      queue_target: 5000,
      pool_size: 50

    config :meadow, WalEx, durable_slot: false
    config :meadow, :indexing_repo, Meadow.Repo

    config :meadow, Meadow.Search.Cluster,
      bulk_page_size: 3,
      bulk_wait_interval: 2,
      embedding_model_id: nil

    config :meadow,
      dc_api: [
        v2: %{
          "api_token_secret" => "TEST_SECRET",
          "api_token_ttl" => 300,
          "base_url" => "http://dcapi-test.northwestern.edu"
        }
      ],
      iiif_distribution_id: nil

    config :meadow, :sitemaps,
      gzip: true,
      store: Sitemapper.S3Store,
      base_url: "http://localhost:3333/",
      sitemap_url: "http://localhost:3333/",
      store_config: [bucket: prefix("upload"), path: ""]

    config :meadow, Meadow.Directory,
      base_url: "http://localhost:3946/directory-search",
      api_key: "directory-api-key"

    config :meadow, MeadowAI,
      metrics_log: [
        group: get_secret(:meadow, ["logging", "log_group"]),
        region: ExAws.Config.new(:s3)[:region],
        stream: "meadow/metrics"
      ]

    config :ex_unit,
      assert_receive_timeout: 500

    config :honeybadger,
      environment_name: :test,
      exclude_envs: [:dev, :test],
      api_key: "abc123",
      origin: "http://localhost:4444"

    config :ueberauth, Ueberauth.Strategy.NuSSO,
      base_url: "https://northwestern-dev.apigee.net/",
      consumer_key: "test-sso-key"
  end
end
