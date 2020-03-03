defmodule Meadow.Data.CollectionsTest do
  use Meadow.DataCase

  alias Meadow.Data.{Collections, Works}
  alias Meadow.Data.Schemas.Collection

  describe "queries" do
    @valid_attrs %{
      name: "Collection 12345",
      description: "A collection",
      keywords: ["one", "two"]
    }
    @invalid_attrs %{name: nil}

    test "list_collections/0 returns all collections" do
      collection_fixture()
      assert length(Collections.list_collections()) == 1
    end

    test "create_collection/1 with valid data creates a collection" do
      assert {:ok, %Collection{} = collection} = Collections.create_collection(@valid_attrs)
    end

    test "update_collection/2 updates a collection" do
      collection = collection_fixture()

      assert {:ok, %Collection{} = collection} =
               Collections.update_collection(collection, %{name: "The new name"})

      updated_collection = Collections.get_collection!(collection.id)
      assert updated_collection.name == "The new name"
    end

    test "create_collection/1 with invalid data does not create a collection" do
      assert {:error, %Ecto.Changeset{}} = Collections.create_collection(@invalid_attrs)
    end

    test "delete_collection/1 deletes a collection" do
      collection = collection_fixture()
      assert {:ok, %Collection{} = collection} = Collections.delete_collection(collection)
      assert Enum.empty?(Collections.list_collections())
    end

    test "get_collection!/1 returns a collection by id" do
      collection = collection_fixture()
      assert %Collection{} = Collections.get_collection!(collection.id)
    end
  end

  describe "representative images" do
    setup do
      collection = collection_fixture()
      work = work_with_file_sets_fixture(1, %{collection_id: collection.id})

      {:ok, %Collection{} = collection} = Collections.set_representative_image(collection, work)

      {:ok, collection: collection, work: work, image_url: work.representative_image}
    end

    test "no representative image assigned", %{collection: collection} do
      {:ok, collection} = Collections.set_representative_image(collection, nil)
      assert(is_nil(collection.representative_image))
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

    test "deleting a work nilifies the representative image", %{
      collection: collection,
      image_url: image_url,
      work: work
    } do
      assert(
        Collections.get_collection!(collection.id) |> Map.get(:representative_image) == image_url
      )

      work |> Works.delete_work()

      assert(is_nil(Collections.get_collection!(collection.id) |> Map.get(:representative_image)))
    end
  end
end
