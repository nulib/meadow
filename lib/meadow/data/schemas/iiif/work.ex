alias IIIF.Presentation.{Canvas, Image, ImageResource, Manifest, Sequence, Service}
alias Meadow.IIIF

defimpl Meadow.IiifManifest.Resource, for: Meadow.Data.Schemas.Work do
  def encode(work) do
    %Manifest{
      id: IIIF.manifest_id(work.id),
      label: work.descriptive_metadata.title,
      description: work.descriptive_metadata.description,
      sequences: [
        %Sequence{
          canvases:
            Enum.map(work.file_sets, fn file_set ->
              %Canvas{
                id: "#{IIIF.manifest_id(work.id)}/canvas/#{file_set.id}",
                label: file_set.metadata.label,
                images: [
                  %Image{
                    resource: %ImageResource{
                      id: IIIF.image_id(file_set.id),
                      label: file_set.metadata.label,
                      service: %Service{
                        id: IIIF.image_service_id(file_set.id)
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
