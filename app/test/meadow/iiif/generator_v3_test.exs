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

      manifest = Generator.create_manifest(work)
      assert {:ok, subject} = Jason.decode(manifest, keys: :atoms)

      manifest_id = IIIF.V3.manifest_id(work.id)
      canvas1_id = IIIF.V3.canvas_id(work.id, file_set.id)
      annotation_page1_id = IIIF.V3.annotation_page_id(work.id, file_set.id, 1)
      annotation1_id = IIIF.V3.annotation_id(work.id, file_set.id, 1, 1)
      canvas2_id = IIIF.V3.canvas_id(work.id, file_set2.id)
      annotation_page2_id = IIIF.V3.annotation_page_id(work.id, file_set2.id, 1)
      annotation2_id = IIIF.V3.annotation_id(work.id, file_set2.id, 1, 1)
      item2_body_id = "http://localhost:8184/iiif/2/#{file_set2.id}/full/max/0/default.jpg"
      item2_service_id = "http://localhost:8184/iiif/2/#{file_set2.id}"

      assert %{
               "@context": "http://iiif.io/api/presentation/3/context.json",
               id: ^manifest_id,
               items: [
                 %{
                   height: 480,
                   id: ^canvas1_id,
                   items: [
                     %{
                       id: ^annotation_page1_id,
                       items: [
                         %{
                           body: %{id: "https://test-streaming-url/bar.m3u8", type: "Video"},
                           id: ^annotation1_id,
                           motivation: "painting",
                           target: ^canvas1_id,
                           type: "Annotation"
                         }
                       ],
                       type: "AnnotationPage"
                     }
                   ],
                   label: %{en: ["This is the label"]},
                   type: "Canvas",
                   width: 640
                 },
                 %{
                   height: 480,
                   id: ^canvas2_id,
                   items: [
                     %{
                       id: ^annotation_page2_id,
                       items: [
                         %{
                           body: %{
                             id: ^item2_body_id,
                             service: [
                               %{
                                 id: ^item2_service_id,
                                 profile: "http://iiif.io/api/image/2/level2.json",
                                 type: "ImageService2"
                               }
                             ],
                             type: "Image"
                           },
                           id: ^annotation2_id,
                           motivation: "painting",
                           target: ^canvas2_id,
                           type: "Annotation"
                         }
                       ],
                       type: "AnnotationPage"
                     }
                   ],
                   label: %{en: ["This should not be in the manifest"]},
                   type: "Canvas",
                   width: 640
                 }
               ],
               label: %{en: ["Test title"]},
               metadata: [
                 %{
                   label: %{en: ["LastModified"]},
                   value: %{en: [manifest_last_modified]}
                 }
               ],
               requiredStatement: %{
                 label: %{en: ["Attribution"]},
                 value: %{en: ["Courtesy of Northwestern University Libraries"]}
               },
               type: "Manifest"
             } = subject

      assert {:ok, timestamp, _} = manifest_last_modified |> DateTime.from_iso8601()
      assert timestamp |> DateTime.diff(DateTime.utc_now(), :second) < 2
    end
  end
end
