defmodule Meadow.Config.Runtime.Dev do
  @moduledoc """
  Load and apply Meadow's runtime configuration for the dev environment
  """

  import Meadow.Config.Runtime

  def configure! do
    import Config

    File.mkdir_p!("priv/cert")
    File.write!("priv/cert/cert.pem", get_secret(:wildcard_ssl, ["certificate"]))
    File.write!("priv/cert/key.pem", get_secret(:wildcard_ssl, ["key"]))

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
        certfile: Path.join(:code.priv_dir(:meadow), "cert/cert.pem"),
        keyfile: Path.join(:code.priv_dir(:meadow), "cert/key.pem")
      ],
      debug_errors: false,
      code_reloader: true,
      check_origin: false,
      watchers: [
        node: [
          "build.js",
          "--watch",
          cd: Path.expand("../assets", __DIR__)
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

    config :meadow,
      index_interval: 30_000,
      mediaconvert_queue: prefix("transcode"),
      mediaconvert_role: get_secret(:meadow, ["transcode", "role_arn"])

    config :ueberauth, Ueberauth,
      providers: [
        nusso:
          {Ueberauth.Strategy.NuSSO,
           [
             base_url: get_secret(:meadow, ["nusso", "base_url"]),
             callback_path: "/auth/nusso/callback",
             callback_port: 3001,
             consumer_key: get_secret(:meadow, ["nusso", "api_key"]),
             include_attributes: false,
             ssl_port: 3001
           ]}
      ]

    if prefix = System.get_env("DEV_PREFIX") do
      config :meadow,
        dc_api: [
          v2: %{
            "api_token_secret" =>
              get_secret(:meadow, ["dc_api", "v2", "api_token_secret"], "DEV_SECRET"),
            "api_token_ttl" => 300,
            "base_url" => "https://#{prefix}.dev.rdc.library.northwestern.edu:3002"
          }
        ]
    end
  end
end
