defmodule Meadow.IIIF.V2.GeneratorTest do
  use Meadow.DataCase
  alias Meadow.IIIF
  alias Meadow.IIIF.V2.Generator
  import Meadow.TestHelpers

  describe "Manifest generation" do
    test "create_manifest/1" do
      work = work_fixture()

      file_set =
        file_set_fixture(%{
          work_id: work.id,
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            location: "foo",
            description: "bar",
            original_filename: "something",
            label: "This is the label"
          }
        })

      _file_set2 =
        file_set_fixture(%{
          work_id: work.id,
          role: %{id: "P", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            location: "foo",
            description: "preservation master",
            original_filename: "something",
            label: "This should not be in the manifest"
          }
        })

      json = """
      {
        \"label\": \"#{work.descriptive_metadata.title}\",
        \"sequences\": [
          {
            \"canvases\": [
              {
                \"height\": \"480\",
                \"images\": [
                  {
                    \"motivation\": \"sc:painting\",
                    \"resource\": {
                      \"description\": \"bar\",
                      \"label\": \"This is the label\",
                      \"service\": {
                        \"profile\": \"http://iiif.io/api/image/2/level2.json\",
                        \"@context\": \"http://iiif.io/api/image/2/context.json\",
                        \"@id\": \"#{IIIF.V2.image_service_id(file_set.id)}\"
                      },
                      \"@id\": \"#{IIIF.V2.image_id(file_set.id)}\",
                      \"@type\": \"dctypes:Image\"
                    },
                    \"@type\": \"oa:Annotation\"
                  }
                ],
                \"label\": \"This is the label\",
                \"width\": \"640\",
                \"@id\": \"#{IIIF.V2.manifest_id(work.id)}/canvas/#{file_set.id}\",
                \"@type\": \"sc:Canvas\"
              }
            ],
            \"@context\": \"http://iiif.io/api/presentation/2/context.json\",
            \"@id\": \"/sequence/normal\",
            \"@type\": \"sc:Sequence\"
          }
        ],
        \"@context\": \"http://iiif.io/api/presentation/2/context.json\",
        \"@id\": \"#{IIIF.V2.manifest_id(work.id)}\",
        \"@type\": \"sc:Manifest\"
      }\
      """

      assert Generator.create_manifest(work) == json
    end
  end

  describe "Collection generation" do
    test "create_collection/1" do
      collection = collection_fixture()
      work = work_fixture(%{collection_id: collection.id})

      json = """
      {
        \"label\": \"#{collection.description}\",
        \"manifests\": [
          {
            \"label\": \"Test title\",
            \"sequences\": [],
            \"@context\": \"http://iiif.io/api/presentation/2/context.json\",
            \"@id\": \"#{IIIF.V2.manifest_id(work.id)}\",
            \"@type\": \"sc:Manifest\"
          }
        ],
        \"@context\": \"http://iiif.io/api/presentation/2/context.json\",
        \"@id\": \"#{collection.id}\",
        \"@type\": \"sc:Collection\"
      }\
      """

      assert Generator.create_collection(collection) == json
    end
  end
end
