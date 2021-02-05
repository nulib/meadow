defmodule MeadowWeb.Resolvers.Data.Batches do
  @moduledoc """
  Absinthe resolver for Batch update related functionality
  """
  alias Meadow.Batches

  def batches(_, _args, _) do
    {:ok, Batches.list_batches()}
  end

  def batch(_, %{id: id}, _) do
    {:ok, Batches.get_batch!(id)}
  end

  def update(_, params, %{context: %{current_user: user}}) do
    with query <- Map.get(params, :query),
         delete <- Map.get(params, :delete),
         add <- Map.get(params, :add),
         replace <- Map.get(params, :replace),
         nickname <- Map.get(params, :nickname) do
      if empty_param(add) and empty_param(delete) and empty_param(replace) do
        {:error, %{message: "No updates specified"}}
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
            {:ok, batch}

          {:error, changeset} ->
            {:error, message: "Could not create batch", details: parse_batch_errors(changeset)}
        end
      end
    end
  end

  def delete(_, params, %{context: %{current_user: user}}) do
    with query <- Map.get(params, :query),
         nickname <- Map.get(params, :nickname) do
      case Batches.create_batch(%{
             nickname: nickname,
             user: user.username,
             query: query,
             type: "delete"
           }) do
        {:ok, batch} ->
          {:ok, batch}

        {:error, changeset} ->
          {:error, message: "Could not create batch", details: parse_batch_errors(changeset)}
      end
    end
  end

  defp parse_batch_errors(changeset) do
    %{
      add: parse_batch_errors(changeset, :add),
      replace: parse_batch_errors(changeset, :replace)
    }
  end

  defp parse_batch_errors(changeset, key) do
    with {error, []} <- changeset.errors |> Keyword.get(key, {"{}", []}) do
      Jason.decode!(error)
      |> Enum.map(fn {field, error} -> {Inflex.camelize(field, :lower), error} end)
      |> Enum.into(%{})
    end
  end

  defp empty_param(nil), do: true
  defp empty_param(%{} = param) when map_size(param) == 0, do: true
  defp empty_param(_), do: false
end
