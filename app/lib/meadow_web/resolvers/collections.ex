defmodule MeadowWeb.Resolvers.Data.Collections do
  @moduledoc """
  Absinthe GraphQL query resolver for Collections

  """
  alias Meadow.Data.{Collections, Works}
  alias Meadow.Utils.ChangesetErrors

  def collections(_, _, _) do
    {:ok, Collections.list_collections()}
  end

  def collection(_, %{collection_id: id}, _) do
    {:ok, Collections.get_collection!(id)}
  end

  def collection_works(collection, _, _) do
    {:ok, Works.get_works_by_collection(collection.id)}
  end

  def create_collection(_, args, _) do
    case Collections.create_collection(args) do
      {:error, changeset} ->
        {:error,
         message: "Could not create collection",
         details: ChangesetErrors.humanize_errors(changeset)}

      {:ok, collection} ->
        {:ok, collection}
    end
  end

  def update_collection(_, args, _) do
    collection = Collections.get_collection!(args[:collection_id])

    case Collections.update_collection(collection, args) do
      {:error, changeset} ->
        {:error,
         message: "Could not update collection",
         details: ChangesetErrors.humanize_errors(changeset)}

      {:ok, collection} ->
        {:ok, collection}
    end
  end

  def add_works(_, %{collection_id: collection_id, work_ids: work_ids}, _) do
    collection = Collections.get_collection!(collection_id)

    case Collections.add_works(collection, work_ids) do
      {:error, error} ->
        {:error, message: "Could not add works to collection", details: error.message}

      {:ok, collection} ->
        {:ok, collection}
    end
  end

  def remove_works(_, %{collection_id: collection_id, work_ids: work_ids}, _) do
    collection = Collections.get_collection!(collection_id)

    case Collections.remove_works(collection, work_ids) do
      {:error, error} ->
        {:error, message: "Could not add works to collection", details: error.message}

      {:ok, collection} ->
        {:ok, collection}
    end
  end

  def set_collection_image(_, %{collection_id: collection_id, work_id: work_id}, _)
      when not is_nil(work_id) do
    collection = Collections.get_collection!(collection_id)
    work = Works.get_work!(work_id)

    case Collections.set_representative_image(collection, work) do
      {:error, changeset} ->
        {:error,
         message: "Could not update collection",
         details: ChangesetErrors.humanize_errors(changeset)}

      {:ok, collection} ->
        {:ok, collection}
    end
  end

  def set_collection_image(_, %{collection_id: collection_id}, _) do
    collection = Collections.get_collection!(collection_id)

    case Collections.set_representative_image(collection, nil) do
      {:error, changeset} ->
        {:error,
         message: "Could not update collection",
         details: ChangesetErrors.humanize_errors(changeset)}

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
          details: ChangesetErrors.humanize_errors(changeset)
        }

      {:ok, collection} ->
        {:ok, collection}
    end
  end
end
