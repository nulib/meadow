defimpl Meadow.Search.Document, for: Meadow.Data.Schemas.Collection do
  alias Meadow.Indexing.{V1, V2}

  def id(collection), do: collection.id

  def encode(collection, 1), do: V1.Collection.encode(collection)
  def encode(collection, 2), do: V2.Collection.encode(collection)
end
