defmodule Meadow.Data.CSV.Export do
  @moduledoc """
  Generates a CSV representation of works matching an Elasticsearch query
  """

  alias Meadow.Data.Schemas.{Work, WorkAdministrativeMetadata, WorkDescriptiveMetadata}
  alias Meadow.Data.Schemas.ValueEntry
  alias Meadow.Repo
  alias Meadow.Search.Config, as: SearchConfig
  alias Meadow.Search.Scroll
  alias NimbleCSV.RFC4180, as: CSV

  import Ecto.Query, only: [from: 2]
  import Meadow.Data.CSV.Utils

  require Logger

  # Works per database round trip when overlaying identified free-text entries
  # onto the indexed hits.
  @overlay_chunk_size 200

  @value_entry_field_names WorkDescriptiveMetadata.value_entry_fields()
                           |> MapSet.new(&Atom.to_string/1)

  @top_level_fields [
    ["id"],
    ["accession_number"],
    ["ark"],
    ["collection", "id"],
    ["published"],
    ["visibility"]
  ]

  @visibility %{
    "Public" => "OPEN",
    "Institution" => "AUTHENTICATED",
    "Private" => "RESTRICTED"
  }

  @status %{
    "Done" => "DONE",
    "In Progress" => "IN PROGRESS",
    "Not Started" => "NOT STARTED"
  }

  @preservation_level %{
    "Level 1" => "1",
    "Level 2" => "2",
    "Level 3" => "3"
  }

  @note_types %{
    "Awards" => "AWARDS",
    "Biographical/Historical Note" => "BIOGRAPHICAL_HISTORICAL_NOTE",
    "Creation/Production Credits" => "CREATION_PRODUCTION_CREDITS",
    "General Note" => "GENERAL_NOTE",
    "Language Note" => "LANGUAGE_NOTE",
    "Local Note" => "LOCAL_NOTE",
    "Performers" => "PERFORMERS",
    "Statement of Responsibility" => "STATEMENT_OF_RESPONSIBILITY",
    "Venue/Event Date" => "VENUE_EVENT_DATE"
  }

  @related_url_types %{
    "Finding Aid" => "FINDING_AID",
    "Hathi Trust Digital Library" => "HATHI_TRUST_DIGITAL_LIBRARY",
    "Related Information" => "RELATED_INFORMATION",
    "Research Guide" => "RESEARCH_GUIDE"
  }

  @library_unit %{
    "Charles Deering McCormick Library of Special Collections" => "SPECIAL_COLLECTIONS",
    "Faculty Collections" => "FACULTY_COLLECTIONS",
    "Government & Geographic Information Collection" =>
      "GOVERNMENT_AND_GEOGRAPHIC_INFORMATION_COLLECTION",
    "Herskovits Library of African Studies" => "HERSKOVITS_LIBRARY",
    "Music Library" => "MUSIC_LIBRARY",
    "Transportation Library" => "TRANSPORTATION_LIBRARY",
    "University (MAIN) Library" => "UNIVERSITY_MAIN_LIBRARY",
    "University Archives" => "UNIVERSITY_ARCHIVES"
  }

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
        :rows -> {generate_rows(query), nil}
      end,
      fn _ -> :ok end
    )
    |> Stream.map(fn thing -> IO.iodata_to_binary(thing) end)
  end

  def stream_csv(query), do: Jason.encode!(query) |> stream_csv()

  def fields do
    @top_level_fields ++
      fields_for(WorkAdministrativeMetadata, "administrativeMetadata") ++
      fields_for(WorkDescriptiveMetadata, "descriptiveMetadata")
  end

  def normalize_field(field_path) do
    case field_path |> List.last() do
      "id" -> field_path |> Enum.map_join("_", &Inflex.underscore/1)
      field_name -> field_name
    end
  end

  defp fields_for(module, _prefix) do
    module.field_names()
    |> Enum.map(fn field -> [Atom.to_string(field)] end)
  end

  def generate_header(query) do
    with fields <- fields() do
      [
        [query | List.duplicate(nil, length(fields) - 1)],
        fields |> Enum.map(&normalize_field/1)
      ]
      |> CSV.dump_to_stream()
    end
  end

  def generate_rows(query) do
    query
    |> Scroll.results(SearchConfig.alias_for(Work, 2))
    |> Stream.chunk_every(@overlay_chunk_size)
    |> Stream.flat_map(&rows_with_identified_entries/1)
    |> CSV.dump_to_stream()
  end

  # The search index deliberately flattens identified free-text entries to bare
  # strings — that shape is public API. The CSV metadata-update round trip needs
  # each item's stable id, so overlay those fields from the works table (the
  # source of truth for identity) one chunk of hits at a time, and export each
  # item as `id:value`. A hit with no database row (e.g. deleted since indexing)
  # falls back to the indexed bare strings.
  defp rows_with_identified_entries(hits) do
    identified = identified_entries(Enum.map(hits, &Map.get(&1, "_id")))

    Enum.map(hits, fn hit ->
      to_row(hit, Map.get(identified, Map.get(hit, "_id"), %{}))
    end)
  end

  defp identified_entries(work_ids) do
    from(w in "works",
      where: w.id in type(^work_ids, {:array, Ecto.UUID}),
      select: {type(w.id, Ecto.UUID), w.descriptive_metadata}
    )
    |> Repo.all()
    |> Map.new()
  end

  defp to_row(hit, identified) do
    fields()
    |> Enum.map(fn field_path ->
      field_content(field_path, hit, identified)
    end)
  rescue
    e ->
      Logger.error("Error generating CSV row #{get_in(hit, ["_id"])}: #{inspect(e)}")
      error_row(hit)
  end

  defp field_content(field_path, hit, identified) do
    case identified_field_entries(field_path, identified) do
      {:ok, entries} ->
        entries
        |> Enum.map(&ValueEntry.to_csv_string/1)
        |> Enum.reject(&is_nil/1)
        |> combine_multivalued_field()

      :error ->
        field_content(field_path, hit)
    end
  end

  defp identified_field_entries([field], identified) when is_map(identified) do
    if MapSet.member?(@value_entry_field_names, field) and is_map_key(identified, field),
      do: {:ok, List.wrap(Map.get(identified, field))},
      else: :error
  end

  defp identified_field_entries(_field_path, _identified), do: :error

  defp error_row(hit) do
    nils = fields() |> Enum.drop(2) |> Enum.map(fn _ -> nil end)
    [Map.get(hit, "_id") | ["ERROR EXPORTING ROW" | nils]]
  end

  defp field_content(["project_" <> field_path], hit) do
    hit |> get_in(["_source" | ["project", field_path]]) |> to_field()
  end

  defp field_content(["visibility"] = field_path, hit) do
    Map.get(@visibility, hit |> get_in(["_source" | field_path])) |> to_field()
  end

  defp field_content(["status"] = field_path, hit) do
    Map.get(@status, hit |> get_in(["_source" | field_path])) |> to_field()
  end

  defp field_content(["preservation_level"] = field_path, hit) do
    Map.get(@preservation_level, hit |> get_in(["_source" | field_path])) |> to_field()
  end

  defp field_content(["library_unit"] = field_path, hit) do
    Map.get(@library_unit, hit |> get_in(["_source" | field_path])) |> to_field()
  end

  defp field_content(["date_created"], hit), do: field_content(["date_created_edtf"], hit)

  defp field_content(field_path, hit) do
    hit |> get_in(["_source" | field_path]) |> to_field()
  end

  defp to_field(value) when is_list(value) do
    value
    |> Enum.map(&to_field/1)
    |> combine_multivalued_field()
  end

  defp to_field(%{"edtf" => value}), do: value

  defp to_field(%{"label_with_role" => _, "facet" => facet}) do
    [id, role, _] = String.split(facet, "|", parts: 3)
    "#{role}:#{id}"
  end

  defp to_field(%{"label" => related_url_label, "url" => url}) do
    prefix = Map.get(@related_url_types, related_url_label)
    Enum.join([prefix, url], ":")
  end

  defp to_field(%{"note" => note, "type" => type}) do
    prefix = Map.get(@note_types, type)
    Enum.join([prefix, note], ":")
  end

  defp to_field(places) when is_list(places) do
    places
    |> Enum.map(fn
      %{"id" => id} when is_binary(id) -> id
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] -> nil
      ids -> combine_multivalued_field(ids)
    end
  end

  defp to_field(%{"id" => id}), do: id

  defp to_field(%{}), do: nil

  defp to_field(nil), do: nil

  defp to_field(value), do: to_string(value)
end
