defmodule MeadowWeb.Resolvers.Data.Batches do
  @moduledoc """
  Absinthe resolver for Batch update related functionality
  """
  alias Meadow.Batches

  def update(_, %{query: query, delete: delete}, _) do
    {_response, _pid} =
      Meadow.Async.run_once("batch_update", fn ->
        Batches.batch_update(query, delete)
      end)

    {:ok, %{message: "Batch started"}}
  end
end
