defimpl Elasticsearch.Document, for: Meadow.Data.Schemas.WorkDescriptiveMetadata do
  alias Meadow.Data.Schemas.ControlledMetadataEntry
  alias Meadow.Data.Schemas.{NoteEntry, RelatedURLEntry}
  alias Meadow.Data.Schemas.WorkDescriptiveMetadata, as: Source

  def id(md), do: md.id
  def routing(_), do: false

  def encode(md) do
    %{
      descriptiveMetadata:
        Source.field_names()
        |> Enum.map(fn field_name ->
          {Inflex.camelize(field_name, :lower), encode_field(Map.get(md, field_name))}
        end)
        |> Enum.into(%{})
    }
  end

  def encode_field([field | []]), do: [encode_field(field)]
  def encode_field([field | fields]), do: [encode_field(field) | encode_field(fields)]

  def encode_field(%ControlledMetadataEntry{role: nil} = field) do
    Map.from_struct(field)
    |> Map.put(:displayFacet, field.term.label)
    |> Map.put(:facet, "#{field.term.id}||#{field.term.label}|")
  end

  def encode_field(%ControlledMetadataEntry{} = field) do
    Map.from_struct(field)
    |> Map.put(:displayFacet, "#{field.term.label} (#{field.role.label})")
    |> Map.put(
      :facet,
      "#{field.term.id}|#{field.role.id}|#{field.term.label} (#{field.role.label})"
    )
  end

  def encode_field(%NoteEntry{} = field), do: Map.from_struct(field)
  def encode_field(%RelatedURLEntry{} = field), do: Map.from_struct(field)

  def encode_field(field), do: field
end
