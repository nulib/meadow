defmodule Meadow.Data.Collections do
  @moduledoc """
  The Collections context.
  """

  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Meadow.Data.Schemas.Collection
  alias Meadow.Data.Works
  alias Meadow.Repo

  require Logger

  def list_collections do
    Repo.all(Collection, preload: :representative_work)
    |> add_representative_image()
  end

  def get_collection!(id) do
    Repo.get!(Collection, id, preload: :representative_work)
    |> add_representative_image()
  end

  def delete_collection(%Collection{} = collection) do
    Repo.delete(collection)
  end

  def create_collection(attrs \\ %{}) do
    %Collection{}
    |> Collection.changeset(attrs)
    |> Repo.insert()
    |> add_representative_image()
  end

  def update_collection(%Collection{} = collection, attrs) do
    collection
    |> Collection.changeset(attrs)
    |> Repo.update()
    |> add_representative_image()
  end

  @doc """
  Sets the representative_work for a collection

  ## Examples

      iex> set_representative_image(collection, work)
      {:ok, %Collection{}}
  """
  def set_representative_image(%Collection{} = collection, work) do
    collection
    |> Repo.preload(:representative_work)
    |> Collection.changeset()
    |> put_assoc(:representative_work, work)
    |> Repo.update()
    |> add_representative_image()
  end

  @doc """
  Sets the value of the representative_image virtual field
  for a collection, list of collections, or stream of collections
  """
  def add_representative_image(%Collection{} = collection) do
    collection =
      if Ecto.assoc_loaded?(collection.representative_work),
        do: collection,
        else: collection |> Repo.preload(:representative_work)

    case collection.representative_work do
      nil ->
        Map.put(collection, :representative_image, nil)

      work ->
        Map.put(
          collection,
          :representative_image,
          work |> Works.add_representative_image() |> Map.get(:representative_image)
        )
    end
  end

  def add_representative_image(%Stream{} = stream),
    do: Stream.map(stream, &add_representative_image/1)

  def add_representative_image(collections) when is_list(collections),
    do: Enum.map(collections, &add_representative_image/1)

  def add_representative_image({:ok, object}),
    do: {:ok, add_representative_image(object)}

  def add_representative_image(x), do: x
end
