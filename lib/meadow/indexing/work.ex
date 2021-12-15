defimpl Elasticsearch.Document, for: Meadow.Data.Schemas.Work do
  alias Elasticsearch.Document.Meadow.Data.Schemas.WorkAdministrativeMetadata,
    as: AdministrativeMetadataDocument

  alias Elasticsearch.Document.Meadow.Data.Schemas.WorkDescriptiveMetadata,
    as: DescriptiveMetadataDocument

  alias Meadow.IIIF
  alias Meadow.Utils.ExtractedMetadata

  def id(work), do: work.id
  def routing(_), do: false

  def encode(work) do
    %{
      accessionNumber: work.accession_number,
      collection: format(work.collection),
      createDate: work.inserted_at,
      batches: work.batches |> Enum.map(& &1.id),
      metadataUpdateJobs: work.metadata_update_jobs |> Enum.map(& &1.id),
      fileSets:
        work.file_sets
        |> Enum.map(fn file_set ->
          %{
            id: file_set.id,
            accessionNumber: file_set.accession_number,
            description: file_set.core_metadata.description,
            label: file_set.core_metadata.label,
            extractedMetadata: ExtractedMetadata.transform(file_set.extracted_metadata)
          }
        end),
      id: work.id,
      iiifManifest: manifest_id(work),
      model: %{application: "Meadow", name: "Work"},
      modifiedDate: work.updated_at,
      project: format(work.project),
      published: work.published,
      readingRoom: work.reading_room,
      representativeFileSet:
        case work.representative_file_set_id do
          nil ->
            %{}

          representative_file_set_id ->
            %{
              fileSetId: representative_file_set_id,
              url: work.representative_image
            }
        end,
      sheet: format(work.ingest_sheet),
      visibility: format(work.visibility),
      workType: format(work.work_type)
    }
    |> Map.merge(AdministrativeMetadataDocument.encode(work.administrative_metadata))
    |> Map.merge(DescriptiveMetadataDocument.encode(work.descriptive_metadata))
    |> copy_field([:descriptiveMetadata, "title"], :title)
    |> copy_field([:descriptiveMetadata, "alternateTitle"], :alternateTitle)
    |> copy_field([:descriptiveMetadata, "description"], :description)
    |> copy_field([:descriptiveMetadata, "creator"], :creator)
    |> copy_field([:descriptiveMetadata, "contributor"], :contributor)
    |> copy_field([:descriptiveMetadata, "dateCreated"], :dateCreated)
    |> copy_field([:descriptiveMetadata, "subject"], :subject)
    |> copy_field([:collection, :title], :collectionTitle)
  end

  defp format(%{id: id, title: title}), do: %{id: id, title: title}
  defp format(%{id: _id, label: _label, scheme: _scheme} = field), do: field
  defp format(_), do: %{}

  defp copy_field(doc, source, dest) do
    Map.put(doc, dest, copy_field(get_in(doc, source)))
  end

  defp copy_field(list) when is_list(list) do
    Enum.map(list, fn entry -> copy_field(entry) end)
  end

  defp copy_field(%{role: %{scheme: "subject_role"}, term: %{label: label}}), do: label
  defp copy_field(%{displayFacet: display_facet}), do: display_facet
  defp copy_field(%{humanized: humanized}), do: humanized
  defp copy_field(value), do: value

  defp manifest_id(%{work_type: %{id: "IMAGE"}} = work), do: IIIF.V2.manifest_id(work.id)
  defp manifest_id(work), do: IIIF.V3.manifest_id(work.id)
end
