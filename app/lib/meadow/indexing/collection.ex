defimpl Elasticsearch.Document, for: Meadow.Data.Schemas.Collection do
  def id(collection), do: collection.id
  def routing(_), do: false

  def encode(collection) do
    collection
    |> Map.put(:representative_image, representative_image(collection))
  end

  defp representative_image(%{represenative_work: %{id: id, representative_image: url}}),
    do: %{workId: id, url: url}

  defp representative_image(_), do: %{}
end
