alias IIIF.V2.Presentation.{Canvas, Image, ImageResource, Manifest, Sequence, Service}
alias Meadow.IIIF

defimpl Meadow.IIIF.V2.Resource, for: Meadow.Data.Schemas.Work do
  def encode(work) do
    %Manifest{
      id: IIIF.V2.manifest_id(work.id),
      label: work.descriptive_metadata.title,
      description: work.descriptive_metadata.description,
      metadata: [
        IIIF.V2.property("LastModified", DateTime.utc_now() |> DateTime.to_iso8601())
      ],
      sequences: [
        %Sequence{
          canvases:
            Enum.map(work.file_sets, fn file_set ->
              %Canvas{
                id: "#{IIIF.V2.manifest_id(work.id)}/canvas/#{file_set.id}",
                label: file_set.core_metadata.label,
                images: [
                  %Image{
                    on: "#{IIIF.V2.manifest_id(work.id)}/canvas/#{file_set.id}",
                    resource: %ImageResource{
                      id: IIIF.V2.image_id(file_set.id),
                      label: file_set.core_metadata.label,
                      description: file_set.core_metadata.description,
                      service: %Service{
                        id: IIIF.V2.image_service_id(file_set.id)
                      }
                    }
                  }
                ]
              }
            end)
        }
      ]
    }
  end
end
