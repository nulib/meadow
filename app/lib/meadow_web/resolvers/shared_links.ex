defmodule MeadowWeb.Resolvers.Data.SharedLinks do
  @moduledoc """
  Resolver for Shared Links
  """

  alias Meadow.Data.SharedLinks

  def generate(_, %{work_id: work_id}, _) do
    SharedLinks.generate(work_id)
  end
end
