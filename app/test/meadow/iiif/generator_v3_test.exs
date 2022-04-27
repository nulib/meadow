defmodule Meadow.IIIF.V3.GeneratorTest do
  use Meadow.DataCase
  alias Meadow.IIIF
  alias Meadow.IIIF.V3.Generator
  import Meadow.TestHelpers

  describe "Manifest generation" do
    test "create_manifest/1" do
      work = work_fixture(%{work_type: %{id: "VIDEO", scheme: "work_type"}})

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

      file_set2 =
        file_set_fixture(%{
          work_id: work.id,
          role: %{id: "X", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
            location: "foo",
            description: "preservation file",
            original_filename: "something",
            label: "This should not be in the manifest"
          }
        })

      json = """
      {
        \"id\": \"#{IIIF.V3.manifest_id(work.id)}\",
        \"items\": [
          {
            \"height\": 480,
            \"id\": \"#{IIIF.V3.canvas_id(work.id, file_set.id)}\",
            \"items\": [
              {
                \"id\": \"#{IIIF.V3.annotation_page_id(work.id, file_set.id, 1)}\",
                \"items\": [
                  {
                    \"body\": {
                      \"id\": \"https://test-streaming-url/bar.m3u8\",
                      \"type\": \"Video\"
                    },
                    \"id\": \"#{IIIF.V3.annotation_id(work.id, file_set.id, 1, 1)}\",
                    \"motivation\": \"painting\",
                    \"target\": \"#{IIIF.V3.canvas_id(work.id, file_set.id)}\",
                    \"type\": \"Annotation\"
                  }
                ],
                \"type\": \"AnnotationPage\"
              }
            ],
            \"label\": {
              \"en\": [
                \"This is the label\"
              ]
            },
            \"type\": \"Canvas\",
            \"width\": 640
          },
          {
            \"height\": 480,
            \"id\": \"#{IIIF.V3.canvas_id(work.id, file_set2.id)}\",
            \"items\": [
              {
                \"id\": \"#{IIIF.V3.annotation_page_id(work.id, file_set2.id, 1)}\",
                \"items\": [
                  {
                    \"body\": {
                      \"id\": \"http://localhost:8184/iiif/2/#{file_set2.id}/full/max/0/default.jpg\",
                      \"service\": [
                        {
                          \"id\": \"http://localhost:8184/iiif/2/#{file_set2.id}\",
                          \"profile\": \"http://iiif.io/api/image/2/level2.json\",
                          \"type\": \"ImageService2\"
                        }
                      ],
                      \"type\": \"Image\"
                    },
                    \"id\": \"#{IIIF.V3.annotation_id(work.id, file_set2.id, 1, 1)}\",
                    \"motivation\": \"painting\",
                    \"target\": \"#{IIIF.V3.canvas_id(work.id, file_set2.id)}\",
                    \"type\": \"Annotation\"
                  }
                ],
                \"type\": \"AnnotationPage\"
              }
            ],
            \"label\": {
              \"en\": [
                \"This should not be in the manifest\"
              ]
            },
            \"type\": \"Canvas\",
            \"width\": 640
          }
        ],
        \"label\": {
          \"en\": [
            \"Test title\"
          ]
        },
        \"requiredStatement\": {
          \"label\": {
            \"en\": [
              \"Attribution\"
            ]
          },
          \"value\": {
            \"en\": [
              \"Courtesy of Northwestern University Libraries\"
            ]
          }
        },
        \"type\": \"Manifest\",
        \"@context\": \"http://iiif.io/api/presentation/3/context.json\"
      }\
      """

      assert Generator.create_manifest(work) == json
    end
  end
end
