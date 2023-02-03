defmodule Meadow.Data.Collections do
  @moduledoc """
  The Collections context.
  """

  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Meadow.Data.Schemas.{Collection, FileSet, Work}
  alias Meadow.Data.{FileSets, Works}
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

  def with_works_and_file_sets(id) do
    Collection
    |> where([collection], collection.id == ^id)
    |> join(:left, [collection], works in assoc(collection, :works))
    |> join(:left, [collection, works], file_sets in assoc(works, :file_sets))
    |> preload([collection, works, file_sets], works: {works, file_sets: file_sets})
    |> Repo.one()
  end

  def delete_collection(%Collection{} = collection) do
    collection
    |> Collection.changeset()
    |> no_assoc_constraint(:works, message: "Works are still associated with this collection.")
    |> Repo.delete()
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

  def get_work_count(collection_id) do
    count =
      from(w in Work, where: w.collection_id == ^collection_id)
      |> Repo.aggregate(:count)

    {:ok, count}
  end

  def add_works(%Collection{} = collection, work_ids) do
    from(w in Work, where: w.id in ^work_ids)
    |> Repo.update_all(set: [collection_id: collection.id, updated_at: DateTime.utc_now()])

    {:ok, get_collection!(collection.id)}
  rescue
    err in Postgrex.Error -> {:error, err.postgres}
    err -> {:error, err}
  end

  def remove_works(%Collection{} = collection, work_ids) do
    from(w in Work, where: w.id in ^work_ids and w.collection_id == ^collection.id)
    |> Repo.update_all(set: [collection_id: nil, updated_at: DateTime.utc_now()])

    {:ok, get_collection!(collection.id)}
  rescue
    err in Postgrex.Error -> {:error, err.postgres}
    err -> {:error, err}
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
        Map.put(
          collection,
          :representative_image,
          FileSets.representative_image_url_for(%FileSet{
            derivatives: %{"pyramid_tiff" => nil},
            id: "00000000-0000-0000-0000-000000000001"
          })
        )

      work ->
        with updated_work <- work |> Works.add_representative_image() do
          collection
          |> Map.put(:representative_work, updated_work)
          |> Map.put(:representative_image, updated_work.representative_image)
        end
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
