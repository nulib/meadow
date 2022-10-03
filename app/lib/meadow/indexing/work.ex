defimpl Meadow.Search.Document, for: Meadow.Data.Schemas.Work do
  alias Meadow.Indexing.{V1, V2}

  def id(work), do: work.id

  def encode(work, 1), do: V1.Work.encode(work)
  def encode(work, 2), do: V2.Work.encode(work)
end
