defimpl Elasticsearch.Document, for: Meadow.Data.Schemas.FileSet do
  alias Meadow.Data.FileSets
  alias Meadow.Utils.ExtractedMetadata

  def id(file_set), do: file_set.id
  def routing(_), do: false

  def encode(file_set) do
    %{
      accessionNumber: file_set.accession_number,
      createDate: file_set.inserted_at,
      description: file_set.core_metadata.description,
      digests: file_set.core_metadata.digests,
      extractedMetadata: extracted_metadata(file_set.extracted_metadata),
      id: file_set.id,
      label: file_set.core_metadata.label,
      mime_type: file_set.core_metadata.mime_type,
      model: %{application: "Meadow", name: "FileSet"},
      modifiedDate: file_set.updated_at,
      posterOffset: file_set.poster_offset,
      rank: file_set.rank,
      representativeImageUrl: FileSets.representative_image_url_for(file_set),
      role: format(file_set.role),
      streamingUrl: FileSets.distribution_streaming_uri_for(file_set),
      visibility: format(file_set.work.visibility),
      webvtt: file_set.structural_metadata.value,
      workId: file_set.work.id,
      indexed_at: NaiveDateTime.utc_now()
    }
  end

  def extracted_metadata(%{"exif" => _} = value), do: ExtractedMetadata.transform(value)
  def extracted_metadata(%{"mediainfo" => _}), do: nil
  def extracted_metadata(value), do: value

  defp format(%{id: id, name: name}), do: %{id: id, name: name}
  defp format(%{id: id, title: title}), do: %{id: id, title: title}
  defp format(%{id: _id, label: _label, scheme: _scheme} = field), do: field
  defp format(_), do: %{}
end
