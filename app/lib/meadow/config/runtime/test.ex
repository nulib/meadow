defmodule Meadow.Config.Runtime.Test do
  @moduledoc """
  Load and apply Meadow's runtime configuration for the test environment
  """

  def configure! do
    import Config

    # We don't run a server during test. If one is required,
    # you can enable the server option below.
    config :meadow, MeadowWeb.Endpoint,
      http: [port: 4002],
      server: false

    config :meadow,
      index_interval: 1234,
      mediaconvert_client: MediaConvert.Mock,
      streaming_url: "https://test-streaming-url/",
      iiif_server_url: "http://localhost:8184/iiif/3/",
      iiif_manifest_url_deprecated:
        "http://test-pyramids.s3.localhost.localstack.cloud:4566/public/",
      digital_collections_url: "https://fen.rdc-staging.library.northwestern.edu/"

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
        buckets: ["test-ingest", "test-uploads"]
      },
      required_checksum_tags: ["computed-md5"],
      checksum_wait_timeout: 15_000

    config :meadow,
      ark: %{
        default_shoulder: "ark:/12345/nu2",
        user: "mockuser",
        password: "mockpassword",
        target_url: "https://devbox.library.northwestern.edu:3333/items/",
        url: "http://localhost:3944/"
      }

    config :meadow, :elasticsearch_retry,
      interval: 100,
      max_retries: 3

    config :authoritex, authorities: [Authoritex.Mock, NUL.Authority]

    config :meadow, Meadow.Repo,
      username: "docker",
      password: "d0ck3r",
      database: "meadow",
      hostname: "localhost",
      port: 5432,
      show_sensitive_data_on_connection_error: true,
      timeout: 60_000,
      connect_timeout: 60_000,
      handshake_timeout: 60_000,
      pool: Ecto.Adapters.SQL.Sandbox,
      queue_target: 5000,
      pool_size: 50

    config :meadow,
      dc_api: [
        v2: %{
          "api_token_secret" => "TEST_SECRET",
          "api_token_ttl" => 300,
          "base_url" => "http://dcapi-test.northwestern.edu"
        }
      ],
      iiif_distribution_id: nil

    config :exldap, :settings,
      base: "OU=test,DC=library,DC=northwestern,DC=edu",
      server: "localhost",
      port: 389,
      user_dn: "cn=Administrator,cn=Users,dc=library,dc=northwestern,dc=edu",
      password: "d0ck3rAdm1n!",
      ssl: false

    config :ex_unit,
      assert_receive_timeout: 500

    config :honeybadger,
      environment_name: :test,
      exclude_envs: [:dev, :test],
      api_key: "abc123",
      origin: "http://localhost:4444"
  end
end
