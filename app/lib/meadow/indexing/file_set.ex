defimpl Elasticsearch.Document, for: Meadow.Data.Schemas.FileSet do
  alias Meadow.Data.FileSets
  alias Meadow.Utils.ExtractedMetadata

  def id(file_set), do: file_set.id
  def routing(_), do: false

  def encode(file_set) do
    file_set
    |> Map.put(:representative_image_url, FileSets.representative_image_url_for(file_set))
    |> Map.put(:streaming_url, FileSets.distribution_streaming_uri_for(file_set))
    |> Map.get_and_update(:extracted_metadata, fn extracted_metadata ->
      {extracted_metadata, ExtractedMetadata.transform(extracted_metadata)}
    end)
    |> then(fn {_, result} -> result end)
  end
end
