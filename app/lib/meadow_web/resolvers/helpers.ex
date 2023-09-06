defmodule MeadowWeb.Resolvers.Helpers do
  @moduledoc """
  Absinthe GraphQL query resolver Random Functions
  """

  alias Meadow.Config
  alias Meadow.Utils.AWS

  def get_dc_api_token(_, _args, _) do
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

  def get_presigned_url(_, %{upload_type: "preservation_check"} = params, _) do
    with {:ok, url} <- AWS.presigned_url(Config.preservation_check_bucket(), params) do
      {:ok, %{url: url}}
    end
  end

  def get_presigned_url(_, params, _) do
    with {:ok, url} <- AWS.presigned_url(Config.upload_bucket(), params) do
      {:ok, %{url: url}}
    end
  end

  def iiif_server_url(_, _args, _) do
    {:ok, %{url: Config.iiif_server_url()}}
  end

  def dcapi_endpoint(_, _args, _) do
    {:ok, %{url: Application.get_env(:meadow, :dc_api) |> get_in([:v2, "base_url"])}}
  end

  def digital_collections_url(_, _args, _) do
    {:ok, %{url: Config.digital_collections_url()}}
  end

  def work_archiver_endpoint(_, _args, _) do
    {:ok, %{url: Config.work_archiver_endpoint()}}
  end
end
