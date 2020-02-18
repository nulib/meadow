alias IIIF.Presentation.{Canvas, Collection, ImageResource, Manifest, Sequence}

alias Meadow.IIIF

defimpl Meadow.IiifManifest.Resource, for: Meadow.Data.Schemas.Collection do
  def encode(collection) do
    %Collection{
      id: collection.id,
      label: collection.description,
      manifests:
        Enum.map(collection.works, fn work ->
          %Manifest{
            id: IIIF.manifest_id(work.id),
            label: work.descriptive_metadata.title,
            sequences:
              Enum.map(work.file_sets, fn file_set ->
                %Sequence{
                  canvases: [
                    %Canvas{
                      images: %ImageResource{
                        id: IIIF.image_id(file_set.id),
                        label: file_set.metadata.description
                      }
                    }
                  ]
                }
              end)
          }
        end)
    }
  end
end
