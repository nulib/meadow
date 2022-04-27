defimpl Elasticsearch.Document, for: Meadow.Data.Schemas.WorkAdministrativeMetadata do
  alias Meadow.Data.Schemas.WorkAdministrativeMetadata, as: Source

  def id(md), do: md.id
  def routing(_), do: false

  def encode(md) do
    %{
      administrativeMetadata:
        Source.field_names()
        |> Enum.map(fn field_name ->
          {Inflex.camelize(field_name, :lower), md |> Map.get(field_name)}
        end)
        |> Enum.into(%{})
    }
  end
end
