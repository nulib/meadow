defmodule MeadowWeb.Resolvers.Data.Batches do
  @moduledoc """
  Absinthe resolver for Batch update related functionality
  """
  alias Meadow.Batches

  def update(_, %{query: query, delete: delete, add: add}, _) do
    if empty_param(add) and empty_param(delete) do
      {:ok, %{message: "No updates specified"}}
    else
      Meadow.Async.run_once("batch_update", fn -> Batches.batch_update(query, delete, add) end)
      {:ok, %{message: "Batch started"}}
    end
  end

  def update(arg1, %{query: query, delete: delete}, arg3),
    do: update(arg1, %{query: query, delete: delete, add: %{descriptive_metadata: %{}}}, arg3)

  defp empty_param(nil), do: true
  defp empty_param(param) when map_size(param) == 0, do: true
  defp empty_param(%{descriptive_metadata: param}) when map_size(param) == 0, do: true
  defp empty_param(_), do: false
end
