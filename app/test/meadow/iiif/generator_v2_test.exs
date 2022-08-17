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
            description: "preservation file",
            original_filename: "something",
            label: "This should not be in the manifest"
          }
        })

      manifest = Generator.create_manifest(work)
      assert {:ok, subject} = Jason.decode(manifest, keys: :atoms)

      manifest_id = IIIF.V2.manifest_id(work.id)
      label = work.descriptive_metadata.title
      canvas_id = "#{IIIF.V2.manifest_id(work.id)}/canvas/#{file_set.id}"
      image_service_id = IIIF.V2.image_service_id(file_set.id)
      image_id = IIIF.V2.image_id(file_set.id)

      assert %{
               "@context": "http://iiif.io/api/presentation/2/context.json",
               "@id": ^manifest_id,
               "@type": "sc:Manifest",
               label: ^label,
               metadata: [
                 %{
                   label: %{en: ["LastModified"]},
                   value: %{en: [manifest_last_modified]}
                 }
               ],
               sequences: [
                 %{
                   "@context": "http://iiif.io/api/presentation/2/context.json",
                   "@id": "/sequence/normal",
                   "@type": "sc:Sequence",
                   canvases: [
                     %{
                       "@id": ^canvas_id,
                       "@type": "sc:Canvas",
                       height: "480",
                       images: [
                         %{
                           "@type": "oa:Annotation",
                           motivation: "sc:painting",
                           on: ^canvas_id,
                           resource: %{
                             "@id": ^image_id,
                             "@type": "dctypes:Image",
                             description: "bar",
                             label: "This is the label",
                             service: %{
                               "@context": "http://iiif.io/api/image/2/context.json",
                               "@id": ^image_service_id,
                               profile: "http://iiif.io/api/image/2/level2.json"
                             }
                           }
                         }
                       ],
                       label: "This is the label",
                       width: "640"
                     }
                   ]
                 }
               ]
             } = subject

      assert {:ok, timestamp, _} = manifest_last_modified |> DateTime.from_iso8601()
      assert timestamp |> DateTime.diff(DateTime.utc_now(), :second) < 2
    end
  end

  describe "Collection generation" do
    test "create_collection/1" do
      collection = collection_fixture()
      work = work_fixture(%{collection_id: collection.id})

      manifest = Generator.create_collection(collection)
      assert {:ok, subject} = Jason.decode(manifest, keys: :atoms)

      manifest_id = collection.id
      collection_label = collection.description
      work_manifest_id = IIIF.V2.manifest_id(work.id)
      work_label = work.descriptive_metadata.title

      assert %{
               label: ^collection_label,
               manifests: [
                 %{
                   label: ^work_label,
                   sequences: [],
                   "@context": "http://iiif.io/api/presentation/2/context.json",
                   "@id": ^work_manifest_id,
                   "@type": "sc:Manifest"
                 }
               ],
               "@context": "http://iiif.io/api/presentation/2/context.json",
               "@id": ^manifest_id,
               "@type": "sc:Collection",
               metadata: [
                 %{
                   label: %{en: ["LastModified"]},
                   value: %{en: [manifest_last_modified]}
                 }
               ]
             } = subject

      assert {:ok, timestamp, _} = manifest_last_modified |> DateTime.from_iso8601()
      assert timestamp |> DateTime.diff(DateTime.utc_now(), :second) < 2
    end
  end
end
