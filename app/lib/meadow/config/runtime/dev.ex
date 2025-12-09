defmodule Meadow.Config.Runtime.Dev do
  @moduledoc """
  Load and apply Meadow's runtime configuration for the dev environment
  """

  import Meadow.Config.Secrets

  defp fetch_cert do
    cert_path = project_root() |> Path.join("priv/cert")
    File.mkdir_p!(cert_path)
    Path.join(cert_path, "cert.pem") |> File.write!(get_secret(:wildcard_ssl, ["certificate"]))
    Path.join(cert_path, "key.pem") |> File.write!(get_secret(:wildcard_ssl, ["key"]))
  end

  def configure! do
    import Meadow.Config.Helper

    fetch_cert()

    config :meadow, Meadow.Repo,
      show_sensitive_data_on_connection_error: true,
      timeout: 60_000,
      connect_timeout: 60_000,
      handshake_timeout: 60_000,
      pool_size: 50

    config :meadow, MeadowWeb.Endpoint,
      https: [
        port: 3001,
        cipher_suite: :strong,
        certfile: Path.join(project_root(), "priv/cert/cert.pem"),
        keyfile: Path.join(project_root(), "priv/cert/key.pem")
      ],
      check_origin: false,
      watchers: [
        node: [
          "build.js",
          "--watch",
          cd: Path.join(project_root(), "assets")
        ]
      ],
      live_reload: [
        patterns: [
          ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
          ~r"priv/gettext/.*(po)$",
          ~r"lib/meadow_web/{live,views}/.*(ex)$",
          ~r"lib/meadow_web/templates/.*(eex)$"
        ]
      ]

    if dev_prefix = System.get_env("DEV_PREFIX"),
      do:
        config(:meadow, MeadowWeb.Endpoint,
          url: [
            scheme: "https",
            host: "#{dev_prefix}.dev.rdc.library.northwestern.edu",
            port: 3001
          ]
        )

    config :meadow,
      index_interval: 30_000,
      mediaconvert_queue: prefix("transcode"),
      mediaconvert_role: get_secret(:meadow, ["transcode", "role_arn"])

    config :meadow,
      iiif_server_url: Path.join(get_secret(:iiif, ["v3"]), prefix()),
      iiif_manifest_url_deprecated: Path.join(get_secret(:iiif, ["base"]), "public/")

    config :meadow, Meadow.Scheduler,
      jobs: [
        # Runs every 10 minutes:
        {"*/10 * * * *", {Meadow.Data.PreservationChecks, :start_job, []}}
      ]

    config :meadow, :ai,
      metrics_log: [
        group: get_secret(:meadow, ["logging", "log_group"]),
        region: ExAws.Config.new(:s3)[:region],
        stream:
          Path.join([
            prefix(),
            "meadow",
            "metrics",
            :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
          ])
      ]

    config :meadow, :sitemaps,
      base_url: "https://dc.library.northwestern.edu/",
      gzip: false,
      store: Sitemapper.FileStore,
      sitemap_url: "https://devbox.library.northwestern.edu:3333/",
      store_config: [path: "priv/static"]

    config :ueberauth, Ueberauth.Strategy.NuSSO,
      callback_port: 3001,
      ssl_port: 3001

    if prefix = System.get_env("DEV_PREFIX") do
      config :meadow,
        dc_api: [
          v2: %{
            "api_token_secret" => get_secret(:dcapi, ["api_token_secret"], "DEV_SECRET"),
            "api_token_ttl" => get_secret(:dcapi, ["api_token_ttl"], 300),
            "base_url" => "https://#{prefix}.dev.rdc.library.northwestern.edu:3002"
          }
        ]
    end
  end
end
