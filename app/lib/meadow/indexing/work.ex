defimpl Elasticsearch.Document, for: Meadow.Data.Schemas.Work do
  alias Meadow.IIIF

  def id(work), do: work.id
  def routing(_), do: false

  def encode(work) do
    work
    |> Map.put(:iiif_manifest, manifest_id(work))
    |> Map.put(:thumbnail, thumbnail(work))
    |> Map.get_and_update(:file_sets, fn file_sets ->
      {file_sets, Enum.map(file_sets, &Elasticsearch.Document.encode/1)}
    end)
    |> then(fn {_, result} -> result end)
  end

  defp manifest_id(%{work_type: %{id: "IMAGE"}} = work), do: IIIF.V2.manifest_id(work.id)
  defp manifest_id(work), do: IIIF.V3.manifest_id(work.id)

  defp thumbnail(%{representative_image: url}) when is_binary(url),
    do: url <> "/full/!300,300/0/default.jpg"

  defp thumbnail(_), do: nil
end
