defmodule Meadow.Runtime.Release do
  @moduledoc false

  import Config
  import Meadow.Runtime

  def configure! do
    config :exldap, :settings,
      port: 636,
      ssl: true

    config :meadow, Meadow.Repo,
      pool_size: environment("DB_POOL_SIZE", cast: :integer, default: 10),
      queue_target: environment("DB_QUEUE_TARGET", cast: :integer, default: 50),
      queue_interval: environment("DB_QUEUE_INTERVAL", cast: :integer, default: 1000)

    config :meadow, Meadow.Search.Cluster,
      default_options: [
        aws: [
          service: "es",
          region: environment("AWS_REGION"),
          access_key: secret(:meadow, dig: [:search, :access_key_id]),
          secret: secret(:meadow, dig: [:search, :secret_access_key])
        ],
        timeout: 20_000,
        recv_timeout: 90_000
      ]

    host = environment("MEADOW_HOSTNAME", default: "example.com")
    port = environment("PORT", cast: :integer, default: 4000)

    config :meadow, MeadowWeb.Endpoint,
      url: [host: host, port: port],
      http: [
        :inet6,
        port: port,
        protocol_options: [
          idle_timeout: :infinity,
          max_header_value_length: 8192
        ]
      ],
      check_origin: environment("ALLOWED_ORIGINS", split: ~r/,\s*/, default: ""),
      secret_key_base: environment("SECRET_KEY_BASE"),
      live_view: [signing_salt: environment("SECRET_KEY_BASE")]

    config :meadow,
      ark: %{
        default_shoulder: secret(:meadow, dig: [:ezid, :shoulder], default: "ark:/12345/nu1"),
        user: secret(:meadow, dig: [:ezid, :user], default: "ark_user"),
        password: secret(:meadow, dig: [:ezid, :password], default: "ark_password"),
        target_url:
          secret(:meadow,
            dig: [:ezid, :target_base_url],
            default: "https://devbox.library.northwestern.edu:3333/items/"
          ),
        url: secret(:meadow, dig: [:ezid, :url], default: "http://localhost:3943")
      },
      environment: :prod,
      environment_prefix: nil,
      multipart_upload_concurrency: environment("MULTIPART_UPLOAD_CONCURRENCY", default: "50"),
      pipeline_delay: environment("PIPELINE_DELAY", default: "120000"),
      sitemaps: [
        gzip: true,
        store: Sitemapper.S3Store,
        store_config: [
          bucket: secret(:meadow, dig: [:buckets, :sitemap]),
          path: "/"
        ],
        sitemap_url: secret(:meadow, dig: [:dc, :base_url])
      ],
      validation_ping_interval: environment("VALIDATION_PING_INTERVAL", default: "1000")

    config :elastix,
      custom_headers:
        {Meadow.Utils.AWS, :add_aws_signature,
         [
           environment("AWS_REGION"),
           secret(:meadow, dig: [:search, :access_key_id]),
           secret(:meadow, dig: [:search, :secret_access_key])
         ]}

    config :hackney,
      max_connections: environment("HACKNEY_MAX_CONNECTIONS", cast: :integer, default: "1000")
  end
end
