defmodule Meadow.Indexing.V2.Work do
  @moduledoc """
  v2 encoding for Works
  """

  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.{ControlledMetadataEntry, NoteEntry, RelatedURLEntry}
  alias Meadow.IIIF

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
      caption: work.descriptive_metadata.caption,
      catalog_key: work.descriptive_metadata.catalog_key,
      collection: format(work.collection),
      contributor: encode_field(work.descriptive_metadata.contributor),
      create_date: work.inserted_at,
      creator: encode_field(work.descriptive_metadata.creator),
      csv_metadata_update_jobs: work.metadata_update_jobs |> Enum.map(& &1.id),
      date_created: encode_field(work.descriptive_metadata.date_created),
      description: work.descriptive_metadata.description,
      file_sets: file_sets(work),
      folder_names: work.descriptive_metadata.folder_name,
      folder_numbers: work.descriptive_metadata.folder_number,
      genre: encode_field(work.descriptive_metadata.genre),
      id: work.id,
      identifier: work.descriptive_metadata.identifier,
      iiif_manifest: manifest_id(work),
      indexed_at: NaiveDateTime.utc_now(),
      keywords: work.descriptive_metadata.keywords,
      legacy_identifier: work.descriptive_metadata.legacy_identifier,
      library_unit: encode_label(work.administrative_metadata.library_unit),
      license: work.descriptive_metadata.license,
      modified_date: work.updated_at,
      notes: encode_field(work.descriptive_metadata.notes),
      physical_description_material: work.descriptive_metadata.physical_description_material,
      physical_description_size: work.descriptive_metadata.physical_description_size,
      preservation_level: encode_label(work.administrative_metadata.preservation_level),
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
  end

  def api_url, do: Application.get_env(:meadow, :dc_api) |> get_in([:v2, "base_url"])

  def encode_label(%{label: label}), do: label
  def encode_label(_), do: nil

  def encode_field([field | []]), do: [encode_field(field)]
  def encode_field([field | fields]), do: [encode_field(field) | encode_field(fields)]

  def encode_field(%ControlledMetadataEntry{role: nil} = field) do
    %{
      id: field.term.id,
      label: field.term.label,
      facet: "#{field.term.id}||#{field.term.label}"
    }
  end

  def encode_field(%ControlledMetadataEntry{} = field) do
    %{
      id: field.term.id,
      label: field.term.label,
      role: field.role.label,
      label_with_role: "#{field.term.label} (#{field.role.label})",
      facet: "#{field.term.id}|#{field.role.id}|#{field.term.label} (#{field.role.label})"
    }
  end

  def encode_field(%NoteEntry{} = field), do: Map.from_struct(field)
  def encode_field(%RelatedURLEntry{} = field), do: Map.from_struct(field)
  def encode_field(%{humanized: humanized}), do: humanized

  def encode_field(field), do: field

  def file_sets(work) do
    Enum.map(work.file_sets, fn file_set ->
      %{
        id: file_set.id,
        label: file_set.core_metadata.label,
        mime_type: file_set.core_metadata.mime_type,
        original_filename: file_set.core_metadata.original_filename,
        poster_offset: file_set.poster_offset,
        rank: file_set.rank,
        representative_image_url: FileSets.representative_image_url_for(file_set),
        role: file_set.role.label,
        streaming_url: FileSets.distribution_streaming_uri_for(file_set)
      }
    end)
  end

  defp format(%{id: id, title: title}), do: %{id: id, title: title}
  defp format(%{id: _id, label: _label, scheme: _scheme} = field), do: Map.delete(field, :scheme)
  defp format(_), do: %{}

  defp manifest_id(%{work_type: %{id: "IMAGE"}} = work), do: IIIF.V2.manifest_id(work.id)
  defp manifest_id(work), do: IIIF.V3.manifest_id(work.id)

  def representative_file_set(nil), do: %{}

  def representative_file_set(work) do
    %{
      id: work.representative_file_set_id,
      url: work.representative_image
    }
  end
end
