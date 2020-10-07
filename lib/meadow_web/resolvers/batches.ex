defmodule MeadowWeb.Resolvers.Data.Batches do
  @moduledoc """
  Absinthe resolver for Batch update related functionality
  """
  alias Meadow.Batches

  def update(_, params, _) do
    with query <- Map.get(params, :query),
         delete <- Map.get(params, :delete),
         add <- Map.get(params, :add),
         replace <- Map.get(params, :replace) do
      if empty_param(add) and empty_param(delete) and empty_param(replace) do
        {:ok, %{message: "No updates specified"}}
      else
        Meadow.Async.run_once("batch_update", fn ->
          Batches.batch_update(query, delete, add, replace)
        end)

        {:ok, %{message: "Batch started"}}
      end
    end
  end

  defp empty_param(nil), do: true
  defp empty_param(%{} = param) when map_size(param) == 0, do: true
  defp empty_param(_), do: false
end
