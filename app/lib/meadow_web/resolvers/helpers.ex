defmodule MeadowWeb.Resolvers.Helpers do
  @moduledoc """
  Absinthe GraphQL query resolver Random Functions
  """

  alias Meadow.Config
  alias Meadow.Utils.AWS

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

  def digital_collections_url(_, _args, _) do
    {:ok, %{url: Config.digital_collections_url()}}
  end

  def work_archiver_endpoint(_, _args, _) do
    {:ok, %{url: Config.work_archiver_endpoint()}}
  end
end
