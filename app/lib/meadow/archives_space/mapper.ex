defmodule Meadow.ArchivesSpace.Mapper do
  @moduledoc """
  Pure functions mapping Meadow works onto ArchivesSpace JSONModel records

  Meadow owns a well-defined slice of a linked archival object: its title;
  the notes Meadow created (description/abstract/userestrict, tagged with
  "Synced from Meadow" labels); subject links (topical subjects and genres);
  linked agents (creators/contributors); creation dates; language materials;
  and the digital object instance pointing back at the published work. Its
  transcriptions become digital_object_components under that digital object.

  Everything else on the archival object is preserved untouched. Meadow's
  contributions are merged replace-only-ours: notes by label, agents by ref,
  dates/languages by value — so archivist-entered data is never clobbered.
  """

  alias Meadow.Config

  @note_label "Synced from Meadow"
  @note_types %{description: "scopecontent", abstract: "abstract"}

  @doc """
  Merges a work's synced fields into an archival object JSON record

  Takes the archival object as currently stored in ArchivesSpace (so the
  current `lock_version` is preserved), the work, a list of ArchivesSpace
  subject URIs, and the URI of the digital object Meadow manages for the
  work (or `nil`).
  """
  def apply_work(archival_object, work, opts \\ []) do
    archival_object
    |> put_title(work)
    |> put_notes(work)
    |> merge_subjects(Keyword.get(opts, :subject_refs, []))
    |> merge_linked_agents(Keyword.get(opts, :linked_agents, []))
    |> put_dates(work)
    |> put_lang_materials(work)
    |> ensure_instance(Keyword.get(opts, :digital_object_uri))
  end

  @doc """
  Builds an ArchivesSpace subject record from a controlled metadata entry

  Returns `nil` for entries whose term has no URI, as ArchivesSpace
  subjects are deduplicated on `authority_id`.
  """
  def subject(%{term: %{id: id, label: label}} = entry) when is_binary(id) do
    %{
      "jsonmodel_type" => "subject",
      "source" => authority_source(id),
      "authority_id" => id,
      "vocabulary" => "/vocabularies/1",
      "terms" => [
        %{
          "jsonmodel_type" => "term",
          "term" => label,
          "term_type" => term_type(Map.get(entry, :role)),
          "vocabulary" => "/vocabularies/1"
        }
      ]
    }
  end

  def subject(_), do: nil

  @doc """
  Builds an ArchivesSpace genre_form subject from a controlled metadata entry

  Genres are modeled as subjects with a `genre_form` term type in
  ArchivesSpace, so they flow through the same subject linking as topical
  subjects.
  """
  def genre_subject(%{term: %{id: id, label: label}}) when is_binary(id) do
    %{
      "jsonmodel_type" => "subject",
      "source" => authority_source(id),
      "authority_id" => id,
      "vocabulary" => "/vocabularies/1",
      "terms" => [
        %{
          "jsonmodel_type" => "term",
          "term" => label,
          "term_type" => "genre_form",
          "vocabulary" => "/vocabularies/1"
        }
      ]
    }
  end

  def genre_subject(_), do: nil

  @doc """
  Builds an ArchivesSpace agent record from a controlled metadata entry

  Returns `{jsonmodel, path}` where `path` is the agent collection endpoint
  (`/agents/people` or `/agents/corporate_entities`). Person vs corporate is
  inferred from the authority URI; ambiguous authorities (LCNAF, VIAF)
  default to person. Returns `nil` for entries whose term has no URI.
  """
  def agent(%{term: %{id: id, label: label}}) when is_binary(id) do
    case agent_type(id) do
      :corporate ->
        {%{
           "jsonmodel_type" => "agent_corporate_entity",
           "publish" => true,
           "names" => [
             %{
               "jsonmodel_type" => "name_corporate_entity",
               "primary_name" => label,
               "sort_name" => label,
               "source" => authority_source(id),
               "authority_id" => id
             }
           ]
         }, "/agents/corporate_entities"}

      :person ->
        {%{
           "jsonmodel_type" => "agent_person",
           "publish" => true,
           "names" => [
             %{
               "jsonmodel_type" => "name_person",
               "primary_name" => label,
               "name_order" => "inverted",
               "sort_name" => label,
               "source" => authority_source(id),
               "authority_id" => id
             }
           ]
         }, "/agents/people"}
    end
  end

  def agent(_), do: nil

  @doc """
  Builds a `linked_agent` entry merged onto an archival object

  `role` is the ArchivesSpace linked-agent role (`creator` for both Meadow
  creators and contributors); `entry` supplies the MARC relator when present
  (contributors carry a `marc_relator` role).
  """
  def linked_agent(uri, entry) do
    %{"ref" => uri, "role" => "creator"}
    |> maybe_put("relator", relator(entry))
  end

  @doc """
  Builds a `digital_object_component` for an access file set

  Carries the file set's label, its IIIF image as a `file_version`, and —
  when `transcription` content is given — a Meadow-labeled
  `note_digital_object` holding the text. `position` orders the component
  within the parent digital object.
  """
  def digital_object_component(
        %{file_set_id: file_set_id, label: label, position: position} = component,
        digital_object_uri
      ) do
    %{
      "jsonmodel_type" => "digital_object_component",
      "component_id" => file_set_id,
      "label" => label,
      "title" => label,
      "publish" => true,
      "position" => position,
      "digital_object" => %{"ref" => digital_object_uri},
      "file_versions" => component_file_versions(Map.get(component, :image_uri)),
      "notes" => component_notes(Map.get(component, :transcription))
    }
  end

  defp component_file_versions(nil), do: []

  defp component_file_versions(image_uri) do
    [
      %{
        "jsonmodel_type" => "file_version",
        "file_uri" => image_uri,
        "use_statement" => "image-service",
        "publish" => true,
        "xlink_show_attribute" => "embed"
      }
    ]
  end

  defp component_notes(nil), do: []
  defp component_notes(""), do: []

  defp component_notes(content) when is_binary(content) do
    [
      %{
        "jsonmodel_type" => "note_digital_object",
        "type" => "note",
        "label" => @note_label,
        "publish" => true,
        "content" => [content]
      }
    ]
  end

  @doc """
  Merges Meadow's transcription note onto an existing component record

  Replaces only the Meadow-labeled note so an archivist's own component
  notes are preserved, and refreshes the label/title/position/file_versions
  Meadow owns while keeping the component's `uri`/`lock_version`.
  """
  def apply_component(existing, desired) do
    archivist_notes =
      existing
      |> Map.get("notes", [])
      |> Enum.reject(&(Map.get(&1, "label") == @note_label))

    existing
    |> Map.merge(Map.drop(desired, ["notes"]))
    |> Map.put("notes", archivist_notes ++ Map.get(desired, "notes", []))
  end

  @doc """
  Builds the digital object record pointing at the work in Digital Collections

  Pass the existing digital object record to preserve its `lock_version`
  and identifier on update.
  """
  def digital_object(work, existing \\ %{}) do
    Map.merge(existing, %{
      "jsonmodel_type" => "digital_object",
      "digital_object_id" => Map.get(existing, "digital_object_id", work.id),
      "title" => work_title(work),
      "publish" => publish?(work),
      "file_versions" => [
        %{
          "jsonmodel_type" => "file_version",
          "file_uri" => digital_collections_url(work),
          "publish" => true,
          "xlink_show_attribute" => "new"
        }
      ]
    })
  end

  @doc "The public Digital Collections URL for a work"
  def digital_collections_url(work) do
    Config.digital_collections_url()
    |> URI.merge("items/#{work.id}")
    |> URI.to_string()
  end

  def note_label, do: @note_label

  defp put_title(archival_object, work) do
    case work_title(work) do
      nil -> archival_object
      title -> Map.put(archival_object, "title", title)
    end
  end

  defp work_title(work), do: work.descriptive_metadata.title

  defp put_notes(archival_object, work) do
    keep =
      archival_object
      |> Map.get("notes", [])
      |> Enum.reject(&(Map.get(&1, "label") == @note_label))

    Map.put(archival_object, "notes", keep ++ meadow_notes(work))
  end

  defp meadow_notes(work) do
    [
      multipart_note(@note_types.description, work.descriptive_metadata.description),
      singlepart_note(@note_types.abstract, work.descriptive_metadata.abstract),
      rights_note(work)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp rights_note(work) do
    contents =
      [rights_statement_text(work.descriptive_metadata.rights_statement)] ++
        [work.descriptive_metadata.terms_of_use]

    case Enum.reject(contents, &(is_nil(&1) or &1 == "")) do
      [] ->
        nil

      values ->
        %{
          "jsonmodel_type" => "note_multipart",
          "type" => "userestrict",
          "label" => @note_label,
          "publish" => true,
          "subnotes" =>
            Enum.map(values, fn value ->
              %{"jsonmodel_type" => "note_text", "content" => value, "publish" => true}
            end)
        }
    end
  end

  defp rights_statement_text(%{label: label, id: id}) when is_binary(label),
    do: "#{label} (#{id})"

  defp rights_statement_text(_), do: nil

  defp multipart_note(_type, []), do: nil

  defp multipart_note(type, values) do
    %{
      "jsonmodel_type" => "note_multipart",
      "type" => type,
      "label" => @note_label,
      "publish" => true,
      "subnotes" =>
        Enum.map(values, fn value ->
          %{"jsonmodel_type" => "note_text", "content" => value, "publish" => true}
        end)
    }
  end

  defp singlepart_note(_type, []), do: nil

  defp singlepart_note(type, values) do
    %{
      "jsonmodel_type" => "note_singlepart",
      "type" => type,
      "label" => @note_label,
      "publish" => true,
      "content" => values
    }
  end

  defp merge_subjects(archival_object, subject_refs) do
    existing = Map.get(archival_object, "subjects", [])
    new_refs = subject_refs |> Enum.map(&%{"ref" => &1})

    subjects =
      (existing ++ new_refs)
      |> Enum.uniq_by(&Map.get(&1, "ref"))

    Map.put(archival_object, "subjects", subjects)
  end

  # linked_agents have no Meadow label, so key by ref: drop any existing entry
  # that points at a Meadow agent ref, then append Meadow's. Archivist-linked
  # agents (other refs) are preserved.
  defp merge_linked_agents(archival_object, []), do: archival_object

  defp merge_linked_agents(archival_object, meadow_agents) do
    meadow_refs = MapSet.new(meadow_agents, &Map.get(&1, "ref"))

    kept =
      archival_object
      |> Map.get("linked_agents", [])
      |> Enum.reject(&MapSet.member?(meadow_refs, Map.get(&1, "ref")))

    Map.put(archival_object, "linked_agents", kept ++ meadow_agents)
  end

  # dates/lang_materials have no Meadow label or stable key, so dedup-merge by
  # value: preserve everything present (archivist data survives) and append
  # only Meadow values not already there. Idempotent across re-syncs.
  defp put_dates(archival_object, work) do
    meadow_dates =
      work.descriptive_metadata.date_created
      |> Enum.map(&date/1)
      |> Enum.reject(&is_nil/1)

    merge_uniq(archival_object, "dates", meadow_dates, &Map.get(&1, "expression"))
  end

  defp date(%{humanized: humanized, edtf: edtf}) when is_binary(humanized),
    do: build_date(humanized, edtf)

  defp date(%{"humanized" => humanized, "edtf" => edtf}) when is_binary(humanized),
    do: build_date(humanized, edtf)

  defp date(_), do: nil

  defp build_date(humanized, edtf) do
    base = %{"jsonmodel_type" => "date", "label" => "creation", "expression" => humanized}

    case Regex.scan(~r/\d{4}/, edtf || "") |> List.flatten() do
      [single] -> Map.merge(base, %{"date_type" => "single", "begin" => single})
      [start, finish | _] -> Map.merge(base, %{"date_type" => "inclusive", "begin" => start, "end" => finish})
      [] -> Map.put(base, "date_type", "inclusive")
    end
  end

  defp put_lang_materials(archival_object, work) do
    meadow_langs =
      work.descriptive_metadata.language
      |> Enum.map(&lang_material/1)
      |> Enum.reject(&is_nil/1)

    merge_uniq(archival_object, "lang_materials", meadow_langs, &get_in(&1, ["language_and_script", "language"]))
  end

  defp lang_material(%{term: %{id: id}}) when is_binary(id) do
    case iso639_code(id) do
      nil ->
        nil

      code ->
        %{
          "jsonmodel_type" => "lang_material",
          "language_and_script" => %{
            "jsonmodel_type" => "language_and_script",
            "language" => code
          }
        }
    end
  end

  defp lang_material(_), do: nil

  defp iso639_code(uri) do
    segment = uri |> String.split("/") |> List.last()
    if is_binary(segment) and Regex.match?(~r/^[a-z]{3}$/, segment), do: segment
  end

  defp merge_uniq(archival_object, _key, [], _value_fun), do: archival_object

  defp merge_uniq(archival_object, key, meadow_values, value_fun) do
    existing = Map.get(archival_object, key, [])
    present = MapSet.new(existing, value_fun)
    additions = Enum.reject(meadow_values, &MapSet.member?(present, value_fun.(&1)))
    Map.put(archival_object, key, existing ++ additions)
  end

  defp ensure_instance(archival_object, nil), do: archival_object

  defp ensure_instance(archival_object, digital_object_uri) do
    instances = Map.get(archival_object, "instances", [])

    if Enum.any?(instances, &(get_in(&1, ["digital_object", "ref"]) == digital_object_uri)) do
      archival_object
    else
      instance = %{
        "jsonmodel_type" => "instance",
        "instance_type" => "digital_object",
        "digital_object" => %{"ref" => digital_object_uri}
      }

      Map.put(archival_object, "instances", instances ++ [instance])
    end
  end

  defp publish?(%{published: true, visibility: %{id: id}}) when id in ["OPEN", "AUTHENTICATED"],
    do: true

  defp publish?(_), do: false

  # Only sources present in ArchivesSpace's default source enumerations;
  # everything else falls back to "local" (the authority_id still carries the URI)
  @authority_sources [
    {"id.loc.gov/authorities/subjects", "lcsh"},
    {"id.loc.gov/authorities/names", "naf"},
    {"id.loc.gov/vocabulary/graphicMaterials", "gmgpc"},
    {"vocab.getty.edu/aat", "aat"},
    {"vocab.getty.edu/tgn", "tgn"},
    {"vocab.getty.edu/ulan", "ulan"},
    {"viaf.org", "viaf"}
  ]

  defp authority_source(uri) do
    @authority_sources
    |> Enum.find_value("local", fn {fragment, source} ->
      if String.contains?(uri, fragment), do: source
    end)
  end

  # Corporate authorities are not reliably distinguishable from persons by URI
  # alone (LCNAF/VIAF are mixed); default to person and let archivists correct.
  defp agent_type(uri) do
    if String.contains?(uri, "corpName") or String.contains?(uri, "/corporate"),
      do: :corporate,
      else: :person
  end

  # Contributors carry a MARC relator code as their role id; creators have none.
  defp relator(%{role: %{scheme: "marc_relator", id: id}}) when is_binary(id),
    do: String.downcase(id)

  defp relator(_), do: nil

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp term_type(%{id: "GEOGRAPHICAL"}), do: "geographic"
  defp term_type(%{id: "TEMPORAL"}), do: "temporal"
  defp term_type(_), do: "topical"
end
