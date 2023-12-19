defmodule Meadow.Runtime.Dev do
  @moduledoc false

  import Config
  import Meadow.Runtime

  def configure! do
    config(:meadow, MeadowWeb.Endpoint,
      https: [
        port: 3001,
        cipher_suite: :strong,
        certfile: secret("wildcard_ssl", dig: [:certificate], to_file: "priv/cert/cert.pem"),
        keyfile: secret("wildcard_ssl", dig: [:key], to_file: "priv/cert/key.pem")
      ]
    )

    config :ueberauth, Ueberauth,
      providers: [
        nusso:
          {Ueberauth.Strategy.NuSSO,
           [
             base_url: secret(:meadow, dig: [:nusso, :base_url]),
             callback_path: "/auth/nusso/callback",
             callback_port: 3001,
             consumer_key: secret(:meadow, dig: [:nusso, :api_key]),
             include_attributes: false,
             ssl_port: 3001
           ]}
      ]

    if prefix = System.get_env("DEV_PREFIX") do
      config :meadow,
        dc_api: [
          v2: %{
            "api_token_secret" =>
              secret(:meadow, dig: [:dc_api, :v2, :api_token_secret], default: "DEV_SECRET"),
            "api_token_ttl" => 300,
            "base_url" => "https://#{prefix}.dev.rdc.library.northwestern.edu:3002"
          }
        ]
    end
  end
end
