defmodule Meadow.Utils.DCAPI do
  @moduledoc """
  Utilities for interacting with the Digital Collections API.
  """

  @doc """
  Generates a JWT token for authenticating with the DC API.
  """
  def superuser_token do
    with api_config <- Application.get_env(:meadow, :dc_api)[:v2],
         issued_at <- DateTime.utc_now(),
         ttl <- Map.get(api_config, "api_token_ttl", 300),
         expires_at <- DateTime.add(issued_at, ttl) do
      token = %{
        iss: "meadow",
        exp: DateTime.to_unix(expires_at),
        iat: DateTime.to_unix(issued_at),
        entitlements: [],
        isLoggedIn: false,
        isSuperUser: true
      }

      {:ok, token} = :jwt.encode("HS256", token, api_config["api_token_secret"])

      {:ok, %{token: token, expires: expires_at}}
    end
  end
end
