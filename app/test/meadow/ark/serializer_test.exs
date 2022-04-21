defmodule Meadow.Ark.SerializerTest do
  use ExUnit.Case, async: false

  alias Meadow.Ark.Serializer

  @response_body "success: ark:/99999/fk4z90ps4x\n_updated: 1630613597\ndatacite.publisher: Test publisher\n_profile: datacite\ndatacite.title: Test title\n_export: yes\ndatacite.creator: Test creator\n_owner: apitest\n_ownergroup: apitest\n_target: https://test/items/123\n_created: 1630613597\ndatacite.publicationyear: 2021\ndatacite.resourcetype: Image\n_status: public\n"

  describe "serialize/1" do
    test "desconstructs a Meadow.Ark and properly handles ANVL escaping of % characters" do
      ark = %Meadow.Ark{
        ark: "ark:/99999/fk4z90ps4x",
        creator: "Test % creator",
        publication_year: "2021",
        publisher: "%Test publisher%",
        resource_type: "Image",
        status: "public",
        target: "https://test/items/123",
        title: "100%"
      }

      assert Serializer.serialize(ark) == "_profile: datacite\ndatacite.creator: Test %25 creator\ndatacite.publicationyear: 2021\ndatacite.publisher: %25Test publisher%25\ndatacite.resourcetype: Image\n_status: public\n_target: https://test/items/123\ndatacite.title: 100%25"
    end
  end

  describe "deserialize/1" do
    test "builds a Meadow.Ark struct" do
      assert %Meadow.Ark{
               ark: "ark:/99999/fk4z90ps4x",
               creator: "Test creator",
               publication_year: "2021",
               publisher: "Test publisher",
               resource_type: "Image",
               status: "public",
               target: "https://test/items/123",
               title: "Test title"
             } = Serializer.deserialize(@response_body)
    end
  end
end
