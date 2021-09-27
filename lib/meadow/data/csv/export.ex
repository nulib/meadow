defmodule Meadow.Data.CSV.Export do
  @moduledoc """
  Generates a CSV representation of works matching an Elasticsearch query
  """

  alias Meadow.Data.Schemas.{WorkAdministrativeMetadata, WorkDescriptiveMetadata}
  alias Meadow.Utils.ElasticsearchResultStream
  alias NimbleCSV.RFC4180, as: CSV

  import Meadow.Data.CSV.Utils

  @exportable_types ["Work"]
  @top_level_fields [
    ["id"],
    ["accessionNumber"],
    ["collection", "id"],
    ["published"],
    ["visibility"]
  ]

  @doc """
  Generates the CSV output for an Elasticsearch query

  Example:
    iex> generate_csv(%{query: %{match_all: %{}}})
    "{\"query\":{\"match_all\":{}}}\r\nid,accession_number..."
  """
  def generate_csv(query) when is_binary(query) do
    query
    |> stream_csv()
    |> Enum.join("")
  end

  def generate_csv(query), do: Jason.encode!(query) |> generate_csv()

  def stream_csv(query) when is_binary(query) do
    Stream.resource(
      fn -> :header end,
      fn
        nil -> {:halt, nil}
        :header -> {generate_header(query), :rows}
        :rows -> {generate_rows(works_only_query(query)), nil}
      end,
      fn _ -> :ok end
    )
    |> Stream.map(fn thing -> IO.iodata_to_binary(thing) end)
  end

  def stream_csv(query), do: Jason.encode!(query) |> stream_csv()

  defp works_only_query(query) do
    with actual_query <- Jason.decode!(query) |> Map.get("query") do
      %{
        query: %{
          bool: %{
            must: [
              %{terms: %{"model.name.keyword" => @exportable_types}},
              actual_query
            ]
          }
        }
      }
      |> Jason.encode!()
    end
  end

  def fields do
    @top_level_fields ++
      fields_for(WorkAdministrativeMetadata, "administrativeMetadata") ++
      fields_for(WorkDescriptiveMetadata, "descriptiveMetadata")
  end

  def normalize_field(field_path) do
    case field_path |> List.last() do
      "id" -> field_path |> Enum.map(&Inflex.underscore/1) |> Enum.join("_")
      field_name -> Inflex.underscore(field_name)
    end
  end

  defp fields_for(module, prefix) do
    apply(module, :field_names, [])
    |> Enum.map(fn field -> [prefix, Inflex.camelize(field, :lower)] end)
  end

  defp generate_header(query) do
    with fields <- fields() do
      [
        [query | List.duplicate(nil, length(fields) - 1)],
        fields |> Enum.map(&normalize_field/1)
      ]
      |> CSV.dump_to_stream()
    end
  end

  defp generate_rows(query) do
    query
    |> ElasticsearchResultStream.results()
    |> Stream.map(&to_row/1)
    |> CSV.dump_to_stream()
  end

  defp to_row(hit) do
    fields()
    |> Enum.map(fn field_path ->
      hit
      |> get_in(["_source" | field_path])
      |> to_field()
    end)
  end

  defp to_field(value) when is_list(value) do
    value
    |> Enum.map(&to_field/1)
    |> combine_multivalued_field()
  end

  defp to_field(%{"edtf" => value}), do: value

  defp to_field(%{"role" => role, "term" => %{"id" => id}}) do
    case normalize_coded_term(role) do
      nil -> id
      prefix -> [prefix, id] |> Enum.join(":")
    end
  end

  defp to_field(%{"label" => related_url_label, "url" => url}) do
    case normalize_coded_term(related_url_label) do
      nil -> url
      prefix -> [prefix, url] |> Enum.join(":")
    end
  end

  defp to_field(%{"id" => id}), do: id

  defp to_field(%{}), do: nil

  defp to_field(value), do: to_string(value)

  defp normalize_coded_term(%{"id" => id}), do: id

  defp normalize_coded_term(_), do: nil
end
