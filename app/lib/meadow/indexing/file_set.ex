defimpl Meadow.Search.Document, for: Meadow.Data.Schemas.FileSet do
  alias Meadow.Indexing.V2

  def id(file_set), do: file_set.id

  def encode(file_set, 2), do: V2.FileSet.encode(file_set)
end
