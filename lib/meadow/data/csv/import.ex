defmodule Meadow.Data.CSV.Import do
  @moduledoc """
  Converts CSV data into Work metadata
  """

  alias Meadow.Data.CSV.Export
  alias Meadow.Data.Schemas.{Work, WorkAdministrativeMetadata, WorkDescriptiveMetadata}
  alias Meadow.Utils.Stream, as: StreamUtil
  alias Meadow.Utils.Truth
  alias NimbleCSV.RFC4180, as: CSV

  import Meadow.Data.CSV.Utils
  require Logger

  @empty_work_map %{administrative_metadata: %{}, descriptive_metadata: %{}}
  @coded_fields ~w(library_unit license preservation_level rights_statement status visibility work_type)a

  defstruct headers: nil, stream: nil

  @doc """
  Reads a stream of CSV data and returns an importable struct

  Example:
    iex> File.stream!("data.csv") |> read_csv()
    %Meadow.Data.CSV.Import{
      headers: [:id, :accession_number, :collection_id, :published, :visibility,
      :library_unit, :preservation_level, :project_name, :project_desc, ...],
      query: "{\"query\":{\"match_all\":{}}}",
      stream: #Stream<[
        enum: #Function<62.104660160/2 in Stream.transform/4>,
        funs: [#Function<34.104660160/1 in Stream.drop/2>]
      ]>
    }
  """
  def read_csv(source) do
    with csv_stream <-
           source |> StreamUtil.by_line() |> CSV.parse_stream(skip_headers: false),
         [headers | stream] <- Enum.drop_while(csv_stream, &(not header_row?(&1))) do
      %__MODULE__{
        headers: Enum.map(headers, &String.to_atom/1),
        stream: stream
      }
    end
  end

  defp header_row?(headers),
    do:
      length(headers) == length(fields()) and
        Enum.all?(headers, &Regex.match?(~r/[a-z_]+/, &1))

  @doc """
  Streams rows from a struct and returns a stream of structured work metadata maps
  Example:
    iex> File.stream!("data.csv") |> read_csv() |> stream() |> Enum.take(2)
    [
      %{
        accession_number: "imipcY0h",
        administrative_metadata: %{...},
        collection_id: nil,
        descriptive_metadata: %{...},
        id: "acaba4aa-91bc-431c-af60-766498a9dacf",
        published: "false",
        reading_room: "false",
        visibility: nil
      },
      %{
        accession_number: "DA0Hc4xG",
        administrative_metadata: %{...},
        collection_id: nil,
        descriptive_metadata: %{...},
        id: "f005bda1-3ad1-4997-8633-9e12d4c64239",
        published: "false",
        reading_room: "false",
        visibility: nil
      }
    ]
  """
  def stream(%__MODULE__{headers: headers, stream: stream}) do
    stream
    |> Stream.map(fn
      [""] -> nil
      row -> row_to_map(row, headers) |> decode_row()
    end)
    |> Stream.filter(&(not is_nil(&1)))
  end

  def fields do
    Export.fields() |> Enum.map(&(Export.normalize_field(&1) |> String.to_atom()))
  end

  defp decode_row(row) do
    row
    |> Enum.reduce(@empty_work_map, fn {field, value}, map ->
      with schema <- schema_for(field) do
        value = if value == "", do: nil, else: value

        decoded_value =
          decode_field(schema.__schema__(:type, field), value)
          |> add_scheme(field)

        put_path =
          case schema do
            Work -> [field]
            WorkAdministrativeMetadata -> [:administrative_metadata, field]
            WorkDescriptiveMetadata -> [:descriptive_metadata, field]
          end

        put_in(map, put_path, decoded_value)
      end
    end)
  end

  defp row_to_map(row, headers), do: Enum.zip(headers, row) |> Enum.into(%{})

  defp add_scheme(value, field) when is_map(value) do
    if Enum.member?(@coded_fields, field),
      do: Map.put(value, :scheme, to_string(field)),
      else: value
  end

  defp add_scheme(value, _), do: value

  defp decode_field({:array, _}, nil), do: []
  defp decode_field({_, _, %Ecto.Embedded{cardinality: :many, related: _}}, nil), do: []
  defp decode_field({_, _, %Ecto.Embedded{cardinality: :one, related: _}}, nil), do: nil
  defp decode_field(_, nil), do: nil

  defp decode_field({:embedded, type}, value), do: decode_field(type, value)

  defp decode_field({_, _, %Ecto.Embedded{cardinality: :one, related: type}}, value),
    do: decode_field({:embedded, type}, value)

  defp decode_field({_, _, %Ecto.Embedded{cardinality: :many, related: type}}, value) do
    value
    |> split_multivalued_field()
    |> Enum.map(&decode_field({:embedded, type}, String.trim(&1)))
  end

  defp decode_field({:array, type}, value) do
    value
    |> split_multivalued_field()
    |> Enum.map(&decode_field(type, &1))
  end

  defp decode_field(:boolean, value) do
    with value <- value |> to_string() |> String.downcase() do
      cond do
        Truth.true?(value) -> true
        Truth.false?(value) -> false
        true -> value
      end
    end
  end

  defp decode_field(type, value) do
    if Kernel.function_exported?(type, :from_string, 1),
      do: type.from_string(value),
      else: value
  end

  defp schema_for(field) do
    [Work, WorkAdministrativeMetadata, WorkDescriptiveMetadata]
    |> Enum.find(& &1.__schema__(:type, field))
  end
end
