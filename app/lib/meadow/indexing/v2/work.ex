defmodule Meadow.Indexing.V2.Work do
  @moduledoc """
  v2 encoding for Works
  """

  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.{ControlledMetadataEntry, NoteEntry, RelatedURLEntry}

  def encode(work) do
    %{
      abstract: work.descriptive_metadata.abstract,
      accession_number: work.accession_number,
      alternate_title: work.descriptive_metadata.alternate_title,
      api_link: Path.join([api_url(), "works", work.id]),
      api_model: "Work",
      ark: work.descriptive_metadata.ark,
      batch_ids: work.batches |> Enum.map(& &1.id),
      box_name: work.descriptive_metadata.box_name,
      box_number: work.descriptive_metadata.box_number,
      canonical_link: Path.join([dc_url(), "items", work.id]),
      caption: work.descriptive_metadata.caption,
      catalog_key: work.descriptive_metadata.catalog_key,
      collection: collection(work.collection),
      contributor: encode_field(work.descriptive_metadata.contributor),
      create_date: work.inserted_at,
      creator: encode_field(work.descriptive_metadata.creator),
      csv_metadata_update_jobs: work.metadata_update_jobs |> Enum.map(& &1.id),
      cultural_context: work.descriptive_metadata.cultural_context,
      date_created_edtf: encode_edtf(work.descriptive_metadata.date_created),
      date_created: encode_field(work.descriptive_metadata.date_created),
      description: work.descriptive_metadata.description,
      file_sets: file_sets(work),
      folder_name: work.descriptive_metadata.folder_name,
      folder_number: work.descriptive_metadata.folder_number,
      genre: encode_field(work.descriptive_metadata.genre),
      id: work.id,
      identifier: work.descriptive_metadata.identifier,
      iiif_manifest: manifest_id(work),
      indexed_at: NaiveDateTime.utc_now(),
      ingest_sheet: format(work.ingest_sheet),
      ingest_project: format(work.project),
      keywords: work.descriptive_metadata.keywords,
      language: encode_field(work.descriptive_metadata.language),
      legacy_identifier: work.descriptive_metadata.legacy_identifier,
      library_unit: encode_label(work.administrative_metadata.library_unit),
      license: format(work.descriptive_metadata.license),
      location: encode_field(work.descriptive_metadata.location),
      modified_date: work.updated_at,
      notes: encode_field(work.descriptive_metadata.notes),
      physical_description_material: work.descriptive_metadata.physical_description_material,
      physical_description_size: work.descriptive_metadata.physical_description_size,
      preservation_level: encode_label(work.administrative_metadata.preservation_level),
      project: encode_project(work.administrative_metadata),
      provenance: work.descriptive_metadata.provenance,
      published: work.published,
      publisher: work.descriptive_metadata.publisher,
      related_material: work.descriptive_metadata.related_material,
      related_url: encode_field(work.descriptive_metadata.related_url),
      representative_file_set: representative_file_set(work),
      rights_holder: work.descriptive_metadata.rights_holder,
      rights_statement: format(work.descriptive_metadata.rights_statement),
      scope_and_contents: work.descriptive_metadata.scope_and_contents,
      series: work.descriptive_metadata.series,
      source: work.descriptive_metadata.source,
      status: encode_label(work.administrative_metadata.status),
      style_period: encode_field(work.descriptive_metadata.style_period),
      subject: encode_field(work.descriptive_metadata.subject),
      table_of_contents: work.descriptive_metadata.table_of_contents,
      technique: encode_field(work.descriptive_metadata.technique),
      terms_of_use: work.descriptive_metadata.terms_of_use,
      thumbnail: Path.join([api_url(), "works", work.id, "thumbnail"]),
      title: work.descriptive_metadata.title,
      visibility: encode_label(work.visibility),
      work_type: encode_label(work.work_type)
    }
    |> Meadow.Utils.Map.nillify_empty()
    |> prepare_embedding_field()
  end

  @embedding_keys [
    :abstract,
    :alternate_title,
    :caption,
    :collection,
    :contributor,
    :creator,
    :date_created,
    :description,
    :genre,
    # :keywords,
    :language,
    :location,
    :physical_description_material,
    :physical_description_size,
    :publisher,
    :scope_and_contents,
    :source,
    :subject,
    :style_period,
    :table_of_contents,
    :title,
    :technique
  ]

  defp prepare_embedding_field(map) do
    value =
      @embedding_keys
      |> Enum.reduce([], fn field_name, acc ->
        v = prepare_embedding_value(Map.get(map, field_name))
        [v | acc]
      end)
      |> List.flatten()
      |> Enum.reject(fn v ->
        is_nil(v) or byte_size(v) == 0
      end)
      |> Enum.join("\n")

    Map.put(map, :embedding_text, value)
  end

  defp prepare_embedding_value(%{label: v}), do: prepare_embedding_value(v)

  defp prepare_embedding_value([]), do: []

  defp prepare_embedding_value([v | list]),
    do: [prepare_embedding_value(v) | prepare_embedding_value(list)]

  defp prepare_embedding_value(v) when is_binary(v), do: v
  defp prepare_embedding_value(_), do: nil

  def api_url, do: Application.get_env(:meadow, :dc_api) |> get_in([:v2, "base_url"])
  def dc_url, do: Application.get_env(:meadow, :digital_collections_url)

  def collection(%{id: id, title: title, description: description}) do
    %{id: id, title: title, description: description}
  end

  def collection(_), do: %{}

  def encode_label(%{label: label}), do: label
  def encode_label(_), do: nil

  def encode_field([field | []]), do: [encode_field(field)]
  def encode_field([field | fields]), do: [encode_field(field) | encode_field(fields)]

  def encode_field(%ControlledMetadataEntry{role: nil} = field) do
    %{
      id: field.term.id,
      label: field.term.label,
      facet: "#{field.term.id}||#{field.term.label}",
      variants: field.term.variants
    }
  end

  def encode_field(%ControlledMetadataEntry{} = field) do
    %{
      id: field.term.id,
      label: field.term.label,
      role: field.role.label,
      label_with_role: "#{field.term.label} (#{field.role.label})",
      facet: "#{field.term.id}|#{field.role.id}|#{field.term.label} (#{field.role.label})",
      variants: field.term.variants
    }
  end

  def encode_field(%NoteEntry{} = field) do
    %{
      note: field.note,
      type: field.type.label
    }
  end

  def encode_field(%RelatedURLEntry{} = field) do
    %{
      url: field.url,
      label: field.label.label
    }
  end

  def encode_field(%{humanized: humanized}), do: humanized

  def encode_field(field), do: field

  def encode_edtf(value) when is_list(value), do: Enum.map(value, &encode_edtf/1)
  def encode_edtf(%{edtf: edtf}), do: edtf
  def encode_edtf(value), do: value

  def encode_project(admin_metadata) do
    %{
      cycle: admin_metadata.project_cycle,
      desc: List.first(admin_metadata.project_desc),
      manager: List.first(admin_metadata.project_manager),
      name: List.first(admin_metadata.project_name),
      proposer: List.first(admin_metadata.project_proposer),
      task_number: List.first(admin_metadata.project_task_number)
    }
  end

  def file_sets(work) do
    Enum.flat_map(["A", "P", "S", "X"], fn role ->
      Enum.map(Meadow.Data.ranked_file_sets_for_work(work.id, role), fn file_set ->
        %{
          id: file_set.id,
          description: file_set.core_metadata.description,
          accession_number: file_set.accession_number,
          duration: FileSets.duration_in_seconds(file_set),
          download_url: FileSets.download_uri_for(file_set),
          height: FileSets.height(file_set),
          label: file_set.core_metadata.label,
          mime_type: file_set.core_metadata.mime_type,
          original_filename: file_set.core_metadata.original_filename,
          poster_offset: file_set.poster_offset,
          rank: file_set.rank,
          representative_image_url: FileSets.representative_image_url_for(file_set),
          role: file_set.role.label,
          streaming_url: FileSets.distribution_streaming_uri_for(file_set),
          webvtt: FileSets.public_vtt_url_for(file_set),
          width: FileSets.width(file_set)
        }
      end)
    end)
  end

  defp format(%{id: id, title: title}), do: %{id: id, title: title}
  defp format(%{id: _id, label: _label, scheme: _scheme} = field), do: Map.delete(field, :scheme)
  defp format(_), do: %{}

  defp manifest_id(work), do: "#{api_url()}/works/#{work.id}?as=iiif"

  def representative_file_set(nil), do: %{}

  def representative_file_set(work) do
    %{
      aspect_ratio: aspect_ratio(work.representative_file_set_id),
      id: work.representative_file_set_id,
      url: work.representative_image
    }
  end

  defp aspect_ratio(nil), do: 1.0

  defp aspect_ratio(representative_file_set_id) do
    case FileSets.get_file_set(representative_file_set_id) do
      nil -> 1.0
      file_set -> FileSets.aspect_ratio(file_set)
    end
  end
end
