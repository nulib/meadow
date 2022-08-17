alias IIIF.V2.Presentation.{Canvas, Collection, ImageResource, Manifest, Sequence}

alias Meadow.IIIF

defimpl Meadow.IIIF.V2.Resource, for: Meadow.Data.Schemas.Collection do
  def encode(collection) do
    %Collection{
      id: collection.id,
      label: collection.description,
      metadata: [
        IIIF.V2.property("LastModified", DateTime.utc_now() |> DateTime.to_iso8601())
      ],
      manifests:
        Enum.map(collection.works, fn work ->
          %Manifest{
            id: IIIF.V2.manifest_id(work.id),
            label: work.descriptive_metadata.title,
            sequences:
              Enum.map(work.file_sets, fn file_set ->
                %Sequence{
                  canvases: [
                    %Canvas{
                      images: %ImageResource{
                        id: IIIF.V2.image_id(file_set.id),
                        label: file_set.core_metadata.description
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
