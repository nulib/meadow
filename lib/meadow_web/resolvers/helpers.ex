defmodule MeadowWeb.Resolvers.Helpers do
  @moduledoc """
  Absinthe GraphQL query resolver Random Functions
  """

  alias Meadow.Config

  def iiif_server_url(_, _args, _) do
    {:ok, %{url: Config.iiif_server_url()}}
  end
end
