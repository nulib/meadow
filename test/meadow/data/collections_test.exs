defmodule Meadow.Data.CollectionsTest do
  use Meadow.DataCase

  alias Meadow.Data.Collections
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
end
