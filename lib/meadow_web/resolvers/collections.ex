defmodule MeadowWeb.Resolvers.Data.Collections do
  @moduledoc """
  Absinthe GraphQL query resolver for Collections

  """
  alias Meadow.Data.Collections
  alias MeadowWeb.Schema.ChangesetErrors

  def collections(_, _, _) do
    {:ok, Collections.list_collections()}
  end

  def collection(_, %{collection_id: id}, _) do
    {:ok, Collections.get_collection!(id)}
  end

  def create_collection(_, args, _) do
    case Collections.create_collection(args) do
      {:error, changeset} ->
        {:error,
         message: "Could not create collection", details: ChangesetErrors.error_details(changeset)}

      {:ok, collection} ->
        {:ok, collection}
    end
  end

  def update_collection(_, args, _) do
    collection = Collections.get_collection!(args[:collection_id])

    case Collections.update_collection(collection, args) do
      {:error, changeset} ->
        {:error,
         message: "Could not update collection", details: ChangesetErrors.error_details(changeset)}

      {:ok, collection} ->
        {:ok, collection}
    end
  end

  def delete_collection(_, args, _) do
    collection = Collections.get_collection!(args[:collection_id])

    case Collections.delete_collection(collection) do
      {:error, changeset} ->
        {
          :error,
          message: "Could not delete collection",
          details: ChangesetErrors.error_details(changeset)
        }

      {:ok, collection} ->
        {:ok, collection}
    end
  end
end
