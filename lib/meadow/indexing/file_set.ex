defimpl Elasticsearch.Document, for: Meadow.Data.Schemas.FileSet do
  alias Meadow.Data.FileSets
  alias Meadow.Utils.ExtractedMetadata

  def id(file_set), do: file_set.id
  def routing(_), do: false

  def encode(file_set) do
    %{
      createDate: file_set.inserted_at,
      description: file_set.core_metadata.description,
      label: file_set.core_metadata.label,
      mime_type: file_set.core_metadata.mime_type,
      model: %{application: "Meadow", name: "FileSet"},
      modifiedDate: file_set.updated_at,
      streamingUrl: FileSets.distribution_streaming_uri_for(file_set),
      role: format(file_set.role),
      visibility: format(file_set.work.visibility),
      workId: file_set.work.id,
      extractedMetadata: ExtractedMetadata.transform(file_set.extracted_metadata)
    }
  end

  defp format(%{id: id, name: name}), do: %{id: id, name: name}
  defp format(%{id: id, title: title}), do: %{id: id, title: title}
  defp format(%{id: _id, label: _label, scheme: _scheme} = field), do: field
  defp format(_), do: %{}
end
