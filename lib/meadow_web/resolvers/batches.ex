defmodule MeadowWeb.Resolvers.Data.Batches do
  @moduledoc """
  Absinthe resolver for Batch update related functionality
  """
  alias Meadow.Batches
  alias MeadowWeb.Schema.ChangesetErrors

  def update(_, params, %{context: %{current_user: user}}) do
    with query <- Map.get(params, :query),
         delete <- Map.get(params, :delete),
         add <- Map.get(params, :add),
         replace <- Map.get(params, :replace),
         nickname <- Map.get(params, :nickname) do
      if empty_param(add) and empty_param(delete) and empty_param(replace) do
        {:ok, %{message: "No updates specified"}}
      else
        case Batches.create_batch(%{
               nickname: nickname,
               user: user.username,
               query: query,
               delete: Jason.encode!(delete),
               add: Jason.encode!(add),
               replace: Jason.encode!(replace),
               type: "update"
             }) do
          {:ok, batch} ->
            {:ok, %{message: "Batch: " <> batch.id <> " has been submitted"}}

          {:error, changeset} ->
            {:error,
             message: "Could not create batch", details: ChangesetErrors.error_details(changeset)}
        end
      end
    end
  end

  defp empty_param(nil), do: true
  defp empty_param(%{} = param) when map_size(param) == 0, do: true
  defp empty_param(_), do: false
end
