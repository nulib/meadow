defimpl Meadow.Search.Document, for: Meadow.Data.Schemas.FileSet do
  alias Meadow.Indexing.{V1, V2}

  def id(file_set), do: file_set.id

  def encode(file_set, 1), do: V1.FileSet.encode(file_set)
  def encode(file_set, 2), do: V2.FileSet.encode(file_set)
end
