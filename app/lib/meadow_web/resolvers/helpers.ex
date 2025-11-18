defmodule MeadowWeb.Resolvers.Helpers do
  @moduledoc """
  Absinthe GraphQL query resolver Random Functions
  """

  alias Meadow.Config
  alias Meadow.Utils.{AWS, DCAPI}

  def get_dc_api_token(_, _args, _) do
    case DCAPI.superuser_token() do
      {:ok, result} -> {:ok, result}
      error -> error
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

  def get_livebook_url(_, _, _) do
    {:ok, %{url: Application.get_env(:meadow, :livebook, []) |> Keyword.get(:url)}}
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
