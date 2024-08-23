defmodule Meadow.Ark.SerializerTest do
  use ExUnit.Case, async: false

  alias Meadow.Ark.Serializer

  @request_payload """
  _profile: datacite
  datacite.creator: Test %25 creator
  datacite.publicationyear: 2021
  datacite.publisher: Publisher%3A Test
  datacite.resourcetype: Image
  _status: public
  _target: https://test/items/123
  datacite.title: 100%25
  """

  describe "serialize/1" do
    test "desconstructs a Meadow.Ark and properly handles ANVL escaping of % characters" do
      ark = %Meadow.Ark{
        ark: "ark:/99999/fk4z90ps4x",
        creator: "Test % creator",
        publication_year: "2021",
        publisher: "Publisher: Test",
        resource_type: "Image",
        status: "public",
        target: "https://test/items/123",
        title: "100%"
      }

      assert Serializer.serialize(ark) == String.trim(@request_payload)
    end
  end

  @response_body """
  success: ark:/99999/fk4z90ps4x
  _updated: 1630613597
  datacite.publisher: Test publisher
  _profile: datacite
  datacite.title: Test title
  _export: yes
  datacite.creator: Test creator
  _owner: apitest
  _ownergroup: apitest
  _target: https://test/items/123
  _created: 1630613597
  datacite.publicationyear: 2021
  datacite.resourcetype: Image
  _status: public
  """

  describe "deserialize/1" do
    test "builds a Meadow.Ark struct" do
      expected = %Meadow.Ark{
        ark: "ark:/99999/fk4z90ps4x",
        creator: "Test creator",
        publication_year: "2021",
        publisher: "Test publisher",
        resource_type: "Image",
        status: "public",
        target: "https://test/items/123",
        title: "Test title"
      }

      assert Serializer.deserialize(@response_body) == expected
    end
  end
end
