defmodule AVR.Migration.Metadata do
  @moduledoc """
  Convert AVR MODS metadata to Meadow WorkDescriptiveMetadata
  """

  alias Meadow.Data.{CodedTerms, Works}
  alias Meadow.Data.Schemas.{ControlledTermCache, FileSet, WorkDescriptiveMetadata}
  alias Meadow.Repo
  alias Meadow.Utils.ChangesetErrors
  alias Meadow.Utils.Stream, as: StreamUtils

  import Ecto.Query
  import SweetXml

  require Logger

  @note_type_map %{
    "awards" => "AWARDS",
    "biographical/historical" => "BIOGRAPHICAL_HISTORICAL_NOTE",
    "creation/production credits" => "CREATION_PRODUCTION_CREDITS",
    "general" => "GENERAL_NOTE",
    "language" => "LANGUAGE_NOTE",
    "local" => "LOCAL_NOTE",
    "performers" => "PERFORMERS",
    "statement of responsibility" => "STATEMENT_OF_RESPONSIBILITY",
    "venue" => "VENUE_EVENT_DATE"
  }

  def work_mods(work_id) do
    work_id
    |> Works.get_work()
    |> fetch_mods()
  end

  def validate_metadata(work) do
    Logger.info(work.id)

    with descriptive_metadata <- work |> fetch_mods() |> convert_mods(),
         changeset <-
           WorkDescriptiveMetadata.changeset(%WorkDescriptiveMetadata{}, descriptive_metadata),
         errors <- ChangesetErrors.humanize_errors(changeset) do
      if not changeset.valid?, do: Logger.warn(errors)
      {work.id, errors}
    end
  end

  def update_work_metadata(work) do
    Logger.info("Converting MODS metadata for work #{work.id}")

    with descriptive_metadata <- work |> fetch_mods() |> convert_mods() do
      case work |> Works.update_work(%{descriptive_metadata: descriptive_metadata}) do
        {:ok, updated} ->
          Logger.info("Updated work #{updated.id}")

        {:error, %Ecto.Changeset{} = changeset} ->
          with error <-
                 ChangesetErrors.humanize_errors(changeset, flatten: [:descriptive_metadata]) do
            Logger.warn("Failed to update work #{work.id}: #{inspect(error)}")
          end

        other ->
          Logger.warn("Failed to update work #{work.id}. Unknown response: #{inspect(other)}")
      end
    end
  end

  def convert_mods(doc) do
    doc
    |> xpath(~x{/mods},
      catalog_key: ~x{.//recordInfo/recordIdentifier[@source='local']/text()}sl |> trim_all(),
      legacy_identifier: ~x{./identifier[@type!="lccn" and @type!="oclc"]/text()}sl |> trim_all(),
      title: ~x{./titleInfo[@usage="primary"]/title/text()}s |> trim_all(),
      alternate_title: ~x{./titleInfo[@type="alternative"]/title/text()}sl |> trim_all(),
      date_created:
        ~x{originInfo/dateCreated[@encoding="edtf"]/text() | originInfo/dateIssued[@encoding="edtf"]/text()}sl
        |> transform(:edtf_date),
      creator:
        ~x{./name[role/roleTerm[@type="text"]="Creator" or role/roleTerm[@type="code"]="cre"]}l
        |> transform(:creator),
      description: ~x{.//abstract[not(@type) or @type="Summary"]/text()}sl |> trim_all(),
      contributor:
        ~x{./name[role/roleTerm[@type="text"]!="Creator" and role/roleTerm[@type!="code"]!="cre"]}l
        |> transform(:contributor),
      publisher: ~x{./originInfo/publisher/text()}sl,
      language: ~x{//language}l |> transform(:language),
      physical_description_material:
        ~x{.//relatedItem[@type="original"]/physicalDescription/extent/text()}sl |> trim_all(),
      related_url: [
        ~x{.//relatedItem[not(@type) and ./location/url]}l,
        label: ~x{./@displayLabel}s |> transform(:related_url_label),
        url: ~x{./location/url/text()}s |> trim_all()
      ],
      genre: ~x{.//genre/text()}sl |> transform(:genre),
      subject: ~x{.//subject}l |> transform(:subject),
      terms_of_use: ~x{.//accessCondition[@type="use and reproduction"]/text()}s |> trim_all(),
      table_of_contents: ~x{.//tableOfContents/text()}sl |> trim_all(),
      notes: ~x{.//note}l |> transform(:note)
    )
  end

  defp trim_all(%SweetXpath{} = sweet_xpath), do: transform_by(sweet_xpath, &trim_all/1)
  defp trim_all(value) when is_binary(value), do: String.trim(value)
  defp trim_all(value) when is_list(value), do: Enum.map(value, &String.trim/1)
  defp trim_all(value), do: value

  defp transform(%SweetXpath{} = sweet_xpath, type),
    do: sweet_xpath |> transform_by(&trim_all/1) |> transform_by(&transform(&1, type))

  defp transform(nodes, type) when is_list(nodes) do
    with [head | tail] <- nodes do
      [transform(head, type) | transform(tail, type)]
    end
    |> Enum.reject(&is_nil/1)
  end

  defp transform(value, :edtf_date), do: String.replace(value, ~r/[uU]/, "X")

  defp transform(value, :genre) do
    case find_matching_authority_record("lcgft", value) do
      nil -> %{term: find_or_create_local_authority(value)}
      record -> %{term: record}
    end
  end

  defp transform(node, :language) do
    language_term =
      case map_language(node) do
        %{id: "", label: label} -> find_matching_authority_record("lclang", label)
        %{id: id, label: _} -> %{id: "http://id.loc.gov/vocabulary/languages/#{id}"}
      end

    %{role: nil, term: language_term}
  end

  defp transform(label, :related_url_label) do
    case label do
      "finding aid" -> %{id: "FINDING_AID", scheme: "related_url"}
      "libguide" -> %{id: "RESEARCH_GUIDE", scheme: "related_url"}
      _ -> %{id: "RELATED_INFORMATION", scheme: "related_url"}
    end
  end

  defp transform(node, :note) do
    case map_note(node) do
      %{note: ""} -> nil
      map -> %{type: %{id: map.note_type, scheme: "note_type"}, note: map.note}
    end
  end

  defp transform(value, :note_type),
    do: Map.get(@note_type_map, value, "GENERAL_NOTE")

  defp transform(node, :subject) do
    role =
      case xpath(node, ~x{./*}) do
        {:xmlElement, :geographic, _, _, _, _, _, _, _, _, _, _} -> "GEOGRAPHICAL"
        _ -> "TOPICAL"
      end

    case map_subject(node) do
      %{term: %{label: ""}} ->
        nil

      %{authority: "", term: %{label: label}} ->
        %{
          role: %{id: role, scheme: "subject_role"},
          term: find_or_create_local_authority(label)
        }

      %{authority: authority, term: %{label: label}} ->
        %{
          role: %{id: role, scheme: "subject_role"},
          term:
            find_matching_authority_record(authority, label) ||
              find_or_create_local_authority(label)
        }
    end
  end

  defp transform(node, :contributor) do
    with %{role: role, label: name} <- map_contributor(node) do
      name
      |> String.trim()
      |> map_creator_or_contributor(role)
    end
  end

  defp transform(node, :creator) do
    xpath(node, ~x{./namePart/text()}s)
    |> String.trim()
    |> map_creator_or_contributor(nil)
  end

  defp map_contributor(node) do
    xmap(node,
      role: [
        ~x{./role},
        id: ~x{roleTerm[@type="code"]/text()}s |> trim_all(),
        label: ~x{roleTerm[@type="text"]/text()}s |> trim_all()
      ],
      label: ~x{./namePart/text()}s |> trim_all()
    )
  end

  defp map_creator_or_contributor(nil, _), do: nil

  defp map_creator_or_contributor("", _), do: nil

  defp map_creator_or_contributor(name, role) do
    with role <- map_marc_relator(role) do
      case find_matching_authority_record("lcnaf", name) do
        nil -> %{role: role, term: find_or_create_local_authority(name)}
        record -> %{role: role, term: record}
      end
    end
  end

  defp map_language(node) do
    xmap(node,
      id: ~x{./languageTerm[@type="code"]/text()}s |> trim_all(),
      label: ~x{./languageTerm[@type="text"]/text()}s |> trim_all()
    )
  end

  defp map_marc_relator(nil), do: nil

  defp map_marc_relator(%{id: id, label: label}) do
    CodedTerms.list_coded_terms("marc_relator")
    |> Enum.find(fn term -> term.id == id or term.label == label end)
    |> Map.from_struct()
    |> Enum.filter(fn
      {:id, _} -> true
      {:label, _} -> true
      {:scheme, _} -> true
      _ -> false
    end)
    |> Enum.into(%{})
  end

  defp map_note(node) do
    xmap(
      node,
      note_type: ~x{./@type}s |> transform(:note_type),
      note: ~x{./text()}s
    )
  end

  defp map_subject(node) do
    xmap(node,
      authority: ~x{./@authority}s |> trim_all(),
      term: [
        ~x{.},
        label: ~x{.//text()}s |> trim_all()
      ]
    )
  end

  defp find_or_create_local_authority(label) do
    find_matching_authority_record("nul-authority", label)
    |> found_authority_record?(label)
  end

  defp found_authority_record?(nil, label) do
    with {:ok, record} <-
           NUL.AuthorityRecords.create_authority_record(%{
             id: "info/nul:" <> Ecto.UUID.generate(),
             label: String.trim(label),
             hint: "__AVR__"
           }) do
      %{id: record.id}
    end
  end

  defp found_authority_record?(record, _), do: record

  def find_matching_authority_record("nul-authority", value) do
    with search_value <- value |> String.trim() do
      from(r in NUL.Schemas.AuthorityRecord, where: r.label == ^search_value)
      |> Repo.all()
      |> match_search_result("nul-authority", value)
    end
  end

  def find_matching_authority_record(authority, value) do
    with search_value <- value |> String.trim() |> String.trim_trailing(".") do
      case from(v in ControlledTermCache, where: like(v.label, ^"#{search_value}%"))
           |> Repo.all()
           |> match_search_result(authority, value) do
        nil -> Authoritex.search(authority, search_value) |> match_search_result(authority, value)
        result -> result
      end
    end
  end

  defp match_search_result({:ok, search_results}, authority, value),
    do: match_search_result(search_results, authority, value)

  defp match_search_result(search_results, authority, value) when is_list(search_results) do
    case search_results |> Enum.find(&value_matches_authority?(&1, authority, value)) do
      %{id: id} -> %{id: id}
      _ -> nil
    end
  end

  defp match_search_result(_, _, _), do: nil

  defp value_matches_authority?(authorized_value, authority, local_value) do
    with {_, found_authority, _} <- Authoritex.authority_for(authorized_value.id) do
      cond do
        found_authority != authority -> false
        local_value == authorized_value.label -> true
        local_value == authorized_value.label <> "." -> true
        local_value <> "." == authorized_value.label -> true
        true -> false
      end
    end
  end

  def fetch_mods(%{file_sets: file_sets}) when is_list(file_sets) do
    file_sets
    |> Enum.find(&(&1.accession_number |> String.match?(~r/:mods$/)))
    |> extract_mods()
  end

  def fetch_mods(%{id: work_id}) do
    from(fs in FileSet,
      where: fs.work_id == ^work_id,
      where: like(fs.accession_number, "%:mods")
    )
    |> Repo.one()
    |> extract_mods()
  end

  defp extract_mods(nil), do: nil

  defp extract_mods(file_set) do
    file_set
    |> Map.get(:core_metadata)
    |> Map.get(:location)
    |> StreamUtils.stream_from()
    |> Enum.into([])
    |> parse()
  end
end
