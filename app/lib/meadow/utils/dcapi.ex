defmodule Meadow.Utils.DCAPI do
  @moduledoc """
  Utility functions for interacting with the Digital Collections API (DCAPI)
  """

  @doc """
  Generate a JWT token for authenticating with the DCAPI.
  ## Parameters
  - ttl: Time to live in seconds
  - opts: Keyword list of options
    - scopes: List of scopes for the token (default: ["read:Public", "read:Published"])
    - entitlements: List of entitlements (default: [])
    - is_logged_in: Boolean indicating if the token is for a logged-in user (default: true)
    - is_superuser: Boolean indicating if the token is for a superuser (default: false)
  ## Returns
  {:ok, %{token: token, expires: expires_at}} | {:error, reason}
  - `{:ok, %{token: token, expires: expires_at}}` - Generated token and expiration time
  - `{:error, reason}` - Error information
  """

  @default_opts [
    entitlements: [],
    scopes: [
      "read:Public",
      "read:Published"
    ],
    is_logged_in: true,
    is_superuser: false
  ]

  def token(ttl, opts \\ []) do
    with api_config <- Application.get_env(:meadow, :dc_api)[:v2],
         issued_at <- DateTime.utc_now(),
         expires_at <- DateTime.add(issued_at, ttl),
         opts <- Keyword.merge(@default_opts, opts) do
      token = %{
        sub: "meadow",
        name: "Meadow Generated Token",
        iss: "meadow",
        exp: DateTime.to_unix(expires_at),
        iat: DateTime.to_unix(issued_at),
        entitlements: opts[:entitlements],
        isLoggedIn: true,
        isSuperUser: opts[:is_superuser],
        scopes: opts[:scopes]
      }

      case :jwt.encode("HS256", token, api_config["api_token_secret"]) do
        {:ok, token} -> {:ok, %{token: token, expires: expires_at}}
        {:error, reason} -> {:error, reason}
      end
    end
  end
end
