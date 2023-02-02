defmodule Meadow.Data.CollectionsTest do
  use Meadow.DataCase

  alias Meadow.Data.{Collections, Works}
  alias Meadow.Data.Schemas.Collection

  describe "queries" do
    @valid_attrs %{
      title: "Collection 12345",
      description: "A collection",
      keywords: ["one", "two"]
    }
    @invalid_attrs %{title: nil}

    test "list_collections/0 returns all collections" do
      collection_fixture()
      assert length(Collections.list_collections()) == 1
    end

    test "create_collection/1 with valid data creates a collection" do
      assert {:ok, %Collection{} = _collection} = Collections.create_collection(@valid_attrs)
    end

    test "update_collection/2 updates a collection" do
      collection = collection_fixture()

      assert {:ok, %Collection{} = collection} =
               Collections.update_collection(collection, %{title: "The new title"})

      updated_collection = Collections.get_collection!(collection.id)
      assert updated_collection.title == "The new title"
    end

    test "create_collection/1 with invalid data does not create a collection" do
      assert {:error, %Ecto.Changeset{}} = Collections.create_collection(@invalid_attrs)
    end

    test "delete_collection/1 deletes a collection" do
      collection = collection_fixture()
      assert {:ok, %Collection{} = _collection} = Collections.delete_collection(collection)
      assert Enum.empty?(Collections.list_collections())
    end

    test "get_collection!/1 returns a collection by id" do
      collection = collection_fixture()
      assert %Collection{} = Collections.get_collection!(collection.id)
    end
  end

  describe "work associations" do
    setup do
      collection = collection_fixture()

      works = [
        work_fixture(%{collection_id: collection.id}),
        work_fixture(%{collection_id: collection.id}),
        work_fixture(),
        work_fixture()
      ]

      {:ok, %{collection: collection |> Repo.preload(:works), works: works}}
    end

    test "add_works/2", %{collection: collection, works: works} do
      assert length(collection.works) == 2

      ids =
        works
        |> Enum.filter(&(&1.collection_id != collection.id))
        |> Enum.map(& &1.id)

      with {:ok, updated} <- Collections.add_works(collection, ids) do
        assert length(Repo.preload(updated, :works).works) == 4
      end
    end

    test "get_work_count/2", %{collection: collection, works: _works} do
      assert length(collection.works) == 2

      assert {:ok, 2} = Collections.get_work_count(collection.id)
    end

    test "remove_works/2", %{collection: collection, works: works} do
      assert length(collection.works) == 2

      ids =
        works
        |> Enum.filter(&(&1.collection_id == collection.id))
        |> Enum.map(& &1.id)

      with {:ok, updated} <- Collections.remove_works(collection, ids) do
        assert Repo.preload(updated, :works).works |> Enum.empty?()
      end
    end
  end

  describe "representative images" do
    setup do
      collection = collection_fixture()
      work = work_with_file_sets_fixture(1, %{collection_id: collection.id})

      {:ok, %Collection{} = collection} = Collections.set_representative_image(collection, work)

      {:ok, collection: collection, work: work, image_url: work.representative_image}
    end

    test "a placeholder image is assigned without a representative work", %{
      collection: collection
    } do
      {:ok, collection} = Collections.set_representative_image(collection, nil)
      assert(collection.representative_image)
    end

    test "list_works/0", %{image_url: image_url} do
      [collection] = Collections.list_collections()
      assert(collection.representative_image == image_url)
    end

    test "get_collection!/1", %{collection: collection, image_url: image_url} do
      assert(
        Collections.get_collection!(collection.id)
        |> Map.get(:representative_image) == image_url
      )
    end

    test "add_representative_image/1 single collection", %{
      collection: collection,
      image_url: image_url
    } do
      collection =
        Collection
        |> Repo.get!(collection.id)
        |> Collections.add_representative_image()

      assert collection.representative_image == image_url
    end

    test "add_representative_image/1 list of collections", %{image_url: image_url} do
      [collection] =
        Collection
        |> Repo.all()
        |> Collections.add_representative_image()

      assert collection.representative_image == image_url
    end

    test "add_representative_image/1 stream of collections", %{image_url: image_url} do
      stream =
        Collection
        |> Repo.stream()
        |> Collections.add_representative_image()

      {:ok, [collection]} = Repo.transaction(fn -> stream |> Enum.into([]) end)
      assert collection.representative_image == image_url
    end

    test "add_representative_image/1 passthrough" do
      assert "Not a collection" |> Collections.add_representative_image() == "Not a collection"
    end

    test "deleting a work sets the placeholder representative image", %{
      collection: collection,
      image_url: image_url,
      work: work
    } do
      assert(
        Collections.get_collection!(collection.id) |> Map.get(:representative_image) == image_url
      )

      work |> Works.delete_work()

      assert(Collections.get_collection!(collection.id) |> Map.get(:representative_image))
    end
  end
end
