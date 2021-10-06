alias IIIF.V3.Presentation.{
  Annotation,
  AnnotationPage,
  Canvas,
  Content,
  Label,
  LabelValue,
  Manifest,
  Service,
  Thumbnail
}

alias Meadow.Data.FileSets
alias Meadow.IIIF

defimpl Meadow.IIIF.V3.Resource, for: Meadow.Data.Schemas.Work do
  def encode(%{work_type: %{id: work_type}} = work) when work_type in ["VIDEO", "AUDIO"] do
    %Manifest{
      id: IIIF.V3.manifest_id(work.id),
      label: manifest_label(work),
      summary: summary(work.descriptive_metadata.description),
      rights: rights_statement(work.descriptive_metadata.rights_statement),
      requiredStatement: %LabelValue{
        label: %Label{en: ["Attribution"]},
        value: %Label{en: ["Courtesy of Northwestern University Libraries"]}
      },
      items: access_files(work) ++ auxiliary_files(work)
    }
  end

  defp access_files(work) do
    work.file_sets
    |> Enum.filter(&FileSets.access?/1)
    |> Enum.map(fn file_set ->
      %Canvas{
        id: IIIF.V3.canvas_id(work.id, file_set.id),
        label: %Label{en: [file_set.core_metadata.label]},
        thumbnail:
          case FileSets.representative_image_url_for(file_set) do
            nil ->
              nil

            thumbnail_url ->
              [
                %Thumbnail{
                  id: thumbnail_url <> "/full/!300,300/0/default.jpg",
                  type: "Image",
                  format: "image/jpeg",
                  height: 300,
                  width: 300,
                  service: [
                    %Service{
                      id: IIIF.V3.image_service_id(file_set.id, "posters"),
                      profile: "http://iiif.io/api/image/2/level2.json",
                      type: "ImageService2"
                    }
                  ]
                }
              ]
          end,
        items: [
          %AnnotationPage{
            id: IIIF.V3.annotation_page_id(work.id, file_set.id, "1"),
            items: access_file_annotations(work, file_set)
          }
        ]
      }
    end)
  end

  defp auxiliary_files(work) do
    work.file_sets
    |> Enum.filter(&FileSets.auxiliary?/1)
    |> Enum.map(fn file_set ->
      %Canvas{
        id: IIIF.V3.canvas_id(work.id, file_set.id),
        label: %Label{en: [file_set.core_metadata.label]},
        items: [
          %AnnotationPage{
            id: IIIF.V3.annotation_page_id(work.id, file_set.id, "1"),
            items: [
              %Annotation{
                id: IIIF.V3.annotation_id(work.id, file_set.id, "1", "1"),
                body: %Content{
                  id: IIIF.V3.image_id(file_set.id, "/full/max/0/default.jpg"),
                  type: "Image",
                  format: file_set.core_metadata.mime_type,
                  height: FileSets.height(file_set),
                  width: FileSets.width(file_set),
                  service: [
                    %Service{
                      id: IIIF.V3.image_service_id(file_set.id),
                      profile: "http://iiif.io/api/image/2/level2.json",
                      type: "ImageService2"
                    }
                  ]
                },
                target: IIIF.V3.canvas_id(work.id, file_set.id)
              }
            ]
          }
        ]
      }
    end)
  end

  defp access_file_annotations(
         work,
         %{structural_metadata: %{type: "webvtt", value: _value}} = file_set
       ) do
    [access_file_media_annotation(work, file_set) | [access_file_vtt_annotation(work, file_set)]]
  end

  defp access_file_annotations(work, file_set) do
    [access_file_media_annotation(work, file_set)]
  end

  defp access_file_media_annotation(work, file_set) do
    %Annotation{
      id: IIIF.V3.annotation_id(work.id, file_set.id, "1", "1"),
      body: %Content{
        id: FileSets.distribution_streaming_uri_for(file_set),
        type: String.capitalize(resource_type(work.work_type.id)),
        format: file_set.core_metadata.mime_type,
        height: FileSets.height(file_set),
        width: FileSets.width(file_set),
        duration: duration_in_seconds(FileSets.duration_in_milliseconds(file_set))
      },
      target: IIIF.V3.canvas_id(work.id, file_set.id)
    }
  end

  defp access_file_vtt_annotation(work, file_set) do
    %Annotation{
      id: IIIF.V3.annotation_id(work.id, file_set.id, "1", "2"),
      motivation: "supplementing",
      body: %Content{
        id: FileSets.public_vtt_url_for(file_set.id),
        type: "Text",
        format: "text/vtt",
        label: %Label{
          en: ["Transcript"]
        },
        language: "en"
      },
      target: IIIF.V3.canvas_id(work.id, file_set.id)
    }
  end

  defp duration_in_seconds(nil), do: nil
  defp duration_in_seconds(duration) when duration > 0, do: duration / 1000
  defp duration_in_seconds(_), do: nil

  def resource_type("AUDIO"), do: "Sound"
  def resource_type(work_type), do: work_type

  defp manifest_label(%{descriptive_metadata: %{title: nil}}), do: nil
  defp manifest_label(%{descriptive_metadata: %{title: title}}), do: %Label{en: [title]}
  defp manifest_label(_), do: nil

  defp summary([]), do: nil
  defp summary(summary), do: %Label{en: summary}

  defp rights_statement(%{id: id}), do: id
  defp rights_statement(_), do: nil
end
