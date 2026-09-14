defmodule Meadow.Data.Schemas.FileSetExtractedMetadata do
  @moduledoc """
  Metadata one tool (`exif` or `mediainfo`) extracted from a FileSet's
  preservation file (`file_set_extracted_metadata`, one row per file set and
  tool). The dimensions the application queries are typed columns; the full
  tool document is kept as `entries` (see
  `Meadow.Data.FileSets.ExtractedMetadata`) and rebuilt by `document/1`.
  """

  import Ecto.Changeset
  use Ecto.Schema
  alias Meadow.Data.FileSets.ExtractedMetadata, as: Codec
  alias Meadow.Data.Schemas.FileSetExtractedMetadataEntry

  @tools ~w(exif mediainfo)

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID
  schema "file_set_extracted_metadata" do
    belongs_to :file_set, Meadow.Data.Schemas.FileSet
    field :tool, :string
    field :tool_version, :string
    field :width, :integer
    field :height, :integer
    field :duration_ms, :float

    has_many :entries, FileSetExtractedMetadataEntry,
      foreign_key: :extracted_metadata_id,
      on_replace: :delete
  end

  def tools, do: @tools

  @doc """
  Params are `%{tool: "exif", document: raw_map}` where `raw_map` is the
  tool's JSON (`%{"tool", "tool_version", "value" => ...}`); the document is
  flattened into entries and its dimensions are derived.
  """
  def changeset(metadata, params) do
    document = Map.get(params, :document) || Map.get(params, "document")
    document = if is_map(document), do: stringify(document), else: %{}

    dims =
      Codec.dimensions(to_string(Map.get(params, :tool) || Map.get(params, "tool")), document)

    metadata
    |> cast(params, [:tool])
    |> validate_required([:tool])
    |> validate_inclusion(:tool, @tools)
    |> put_change(:tool_version, document["tool_version"])
    |> put_change(:width, dims.width)
    |> put_change(:height, dims.height)
    |> put_change(:duration_ms, dims.duration_ms)
    |> put_assoc(:entries, entries_for(document))
  end

  defp entries_for(document) when map_size(document) == 0, do: []

  defp entries_for(document) do
    document
    |> Codec.flatten()
    |> Enum.map(&struct(FileSetExtractedMetadataEntry, &1))
  end

  @doc "The tool's document exactly as it was stored (`%{\"tool\" => ..., \"tool_version\" => ..., \"value\" => ...}`)"
  def document(%__MODULE__{} = metadata) do
    case Codec.unflatten(metadata.entries || []) do
      nil -> %{}
      doc -> doc
    end
  end

  @doc "Normalize the legacy `%{\"exif\" => doc, \"mediainfo\" => doc}` map into tool params"
  def to_params(nil), do: []
  def to_params(list) when is_list(list), do: Enum.map(list, &tool_params/1)

  def to_params(%{} = map) when not is_struct(map),
    do: Enum.map(map, fn {tool, document} -> %{tool: to_string(tool), document: document} end)

  defp tool_params(%__MODULE__{id: id, tool: tool} = metadata),
    do: %{id: id, tool: tool, document: document(metadata)}

  defp tool_params(%{} = map) do
    %{
      id: Map.get(map, :id) || Map.get(map, "id"),
      tool: to_string(Map.get(map, :tool) || Map.get(map, "tool")),
      document: Map.get(map, :document) || Map.get(map, "document")
    }
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  # Tool documents come from JSON (string keys) or Elixir callers (atom keys)
  defp stringify(%{} = map) when not is_struct(map),
    do: Map.new(map, fn {k, v} -> {to_string(k), stringify(v)} end)

  defp stringify(list) when is_list(list), do: Enum.map(list, &stringify/1)
  defp stringify(other), do: other

  @doc "The legacy `%{tool => document}` map for a list of tool rows"
  def to_map(list) when is_list(list), do: Map.new(list, &{&1.tool, document(&1)})
  def to_map(%{} = map) when not is_struct(map), do: map
  def to_map(_), do: %{}
end
