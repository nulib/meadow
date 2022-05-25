defimpl Elasticsearch.Document, for: Meadow.Data.Schemas.Collection do
  def id(collection), do: collection.id
  def routing(_), do: false

  def encode(collection) do
    representative_image =
      case collection.representative_work do
        nil ->
          %{}

        work ->
          %{
            workId: work.id,
            url: work.representative_image
          }
      end

    collection
    |> Map.put(:representative_image, representative_image)
  end
end
