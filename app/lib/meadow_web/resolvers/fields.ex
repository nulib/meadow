defmodule MeadowWeb.Resolvers.Fields do
  @moduledoc """
  Absinthe resolver for Fields queries
  """
  alias Meadow.Data.Fields

  def describe(_, %{id: id}, _) do
    {:ok, Fields.describe(id)}
  end

  def describe(_, _, _) do
    {:ok, Fields.describe()}
  end
end
