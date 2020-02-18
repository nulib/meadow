defmodule Meadow.Iiif.GeneratorTest do
  use Meadow.DataCase
  alias Meadow.IIIF
  alias Meadow.Iiif.Generator
  import Meadow.TestHelpers

  describe "Manifest generation" do
    test "create_manifest/1" do
      work = work_fixture()

      file_set =
        file_set_fixture(%{
          work_id: work.id,
          metadata: %{
            location: "foo",
            description: "bar",
            original_filename: "something",
            label: "This is the label"
          }
        })

      json =
        "{\n  \"label\": \"#{work.descriptive_metadata.title}\",\n  \"sequences\": [\n    {\n      \"canvases\": [\n        {\n          \"height\": \"480\",\n          \"images\": [\n            {\n              \"motivation\": \"sc:painting\",\n              \"resource\": {\n                \"label\": \"This is the label\",\n                \"service\": {\n                  \"profile\": \"http://iiif.io/api/image/2/level2.json\",\n                  \"@context\": \"http://iiif.io/api/image/2/context.json\",\n                  \"@id\": \"#{
          IIIF.image_service_id(file_set.id)
        }\"\n                },\n                \"@id\": \"#{IIIF.image_id(file_set.id)}\",\n                \"@type\": \"dctypes:Image\"\n              },\n              \"@type\": \"oa:Annotation\"\n            }\n          ],\n          \"label\": \"This is the label\",\n          \"width\": \"640\",\n          \"@id\": \"#{
          IIIF.manifest_id(work.id)
        }/canvas/#{file_set.id}\",\n          \"@type\": \"sc:Canvas\"\n        }\n      ],\n      \"@context\": \"http://iiif.io/api/presentation/2/context.json\",\n      \"@id\": \"/sequence/normal\",\n      \"@type\": \"sc:Sequence\"\n    }\n  ],\n  \"@context\": \"http://iiif.io/api/presentation/2/context.json\",\n  \"@id\": \"#{
          IIIF.manifest_id(work.id)
        }\",\n  \"@type\": \"sc:Manifest\"\n}"

      assert Generator.create_manifest(work) == json
    end
  end

  describe "Collection generation" do
    test "create_collection/1" do
      collection = collection_fixture()
      work = work_fixture(%{collection_id: collection.id})

      json =
        "{\n  \"label\": \"#{collection.description}\",\n  \"manifests\": [\n    {\n      \"label\": \"Test title\",\n      \"sequences\": [],\n      \"@context\": \"http://iiif.io/api/presentation/2/context.json\",\n      \"@id\": \"#{
          IIIF.manifest_id(work.id)
        }\",\n      \"@type\": \"sc:Manifest\"\n    }\n  ],\n  \"@context\": \"http://iiif.io/api/presentation/2/context.json\",\n  \"@id\": \"#{
          collection.id
        }\",\n  \"@type\": \"sc:Collection\"\n}"

      assert Generator.create_collection(collection) == json
    end
  end
end
