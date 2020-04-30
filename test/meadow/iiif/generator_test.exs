defmodule Meadow.IIIF.GeneratorTest do
  use Meadow.DataCase
  alias Meadow.IIIF
  alias Meadow.IIIF.Generator
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

      expected = %{
        "label" => List.first(work.descriptive_metadata.title),
        "sequences" => [
          %{
            "canvases" => [
              %{
                "height" => "480",
                "images" => [
                  %{
                    "motivation" => "sc:painting",
                    "resource" => %{
                      "label" => "This is the label",
                      "service" => %{
                        "profile" => "http://iiif.io/api/image/2/level2.json",
                        "@context" => "http://iiif.io/api/image/2/context.json",
                        "@id" => IIIF.image_service_id(file_set.id)
                      },
                      "@id" => IIIF.image_id(file_set.id),
                      "@type" => "dctypes:Image"
                    },
                    "@type" => "oa:Annotation"
                  }
                ],
                "label" => "This is the label",
                "width" => "640",
                "@id" => "#{IIIF.manifest_id(work.id)}/canvas/#{file_set.id}",
                "@type" => "sc:Canvas"
              }
            ],
            "@context" => "http://iiif.io/api/presentation/2/context.json",
            "@id" => "/sequence/normal",
            "@type" => "sc:Sequence"
          }
        ],
        "@context" => "http://iiif.io/api/presentation/2/context.json",
        "@id" => IIIF.manifest_id(work.id),
        "@type" => "sc:Manifest"
      }

      assert Generator.create_manifest(work) |> Jason.decode!() == expected
    end
  end

  describe "Collection generation" do
    test "create_collection/1" do
      collection = collection_fixture()
      work = work_fixture(%{collection_id: collection.id})

      expected = %{
        "label" => collection.description,
        "manifests" => [
          %{
            "label" => "Test title",
            "sequences" => [],
            "@context" => "http://iiif.io/api/presentation/2/context.json",
            "@id" => IIIF.manifest_id(work.id),
            "@type" => "sc:Manifest"
          }
        ],
        "@context" => "http://iiif.io/api/presentation/2/context.json",
        "@id" => collection.id,
        "@type" => "sc:Collection"
      }

      assert Generator.create_collection(collection) |> Jason.decode!() == expected
    end
  end
end
