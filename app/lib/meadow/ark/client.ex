defmodule Meadow.Ark.Client do
  @moduledoc """
  Req-based client for the CDLib EZID API
  """

  use Meadow.HTTP.Base
  alias Meadow.Config

  def preprocess_opts(opts) do
    with config <- Config.ark_config(),
         credentials <- [config.user, config.password] |> Enum.join(":") do
      opts
      |> Keyword.put_new(:base_url, config.url)
      |> Keyword.put_new(:auth, {:basic, credentials})
    end
  end
end
