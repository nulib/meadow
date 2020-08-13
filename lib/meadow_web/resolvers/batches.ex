defmodule MeadowWeb.Resolvers.Data.Batches do
  @moduledoc """
  Absinthe resolver for Batch update related functionality
  """
  alias Meadow.Batches

  def update(_, %{query: _query, delete: delete, add: add}, _)
      when map_size(delete) == 0 and map_size(add) == 0 do
    {:ok, %{message: "No updates specified"}}
  end

  def update(_, %{query: query, delete: delete, add: add}, _) do
    {_response, _pid} =
      Meadow.Async.run_once("batch_update", fn ->
        Batches.batch_update(query, delete, add)
      end)

    {:ok, %{message: "Batch started"}}
  end
end
