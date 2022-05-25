defimpl Elasticsearch.Document, for: Meadow.Data.Schemas.Work do
  def id(work), do: work.id
  def routing(_), do: false

  def encode(work) do
    work
    |> Map.get_and_update(:file_sets, fn file_sets ->
      {file_sets, Enum.map(file_sets, &Elasticsearch.Document.encode/1)}
    end)
    |> then(fn {_, result} -> result end)
  end
end
