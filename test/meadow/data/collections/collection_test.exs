defmodule Meadow.Data.Collections.CollectionTest do
  use Meadow.DataCase

  alias Meadow.Data.Collections.Collection

  describe "collections" do
    @valid_attrs %{
      name: "A Sample Collection",
      description: "A test description",
      keywords: ["one", "two", "three"]
    }

    test "created collection has a ULID identifier" do
      {:ok, collection} = %Collection{} |> Collection.changeset(@valid_attrs) |> Repo.insert()

      assert {:ok, <<data::binary-size(16)>>} = Ecto.ULID.dump(collection.id)
    end

    test "changeset is invalid if collection name is used already" do
      %Collection{}
      |> Collection.changeset(@valid_attrs)
      |> Repo.insert!()

      collection2 =
        %Collection{}
        |> Collection.changeset(@valid_attrs)

      assert {:error, changeset} = Repo.insert(collection2)
      assert {"has already been taken", _} = changeset.errors[:name]
    end
  end
end
