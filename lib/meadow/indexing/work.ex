defimpl Elasticsearch.Document, for: Meadow.Data.Schemas.Work do
  alias Elasticsearch.Document.Meadow.Data.Schemas.WorkAdministrativeMetadata,
    as: AdministrativeMetadataDocument

  alias Elasticsearch.Document.Meadow.Data.Schemas.WorkDescriptiveMetadata,
    as: DescriptiveMetadataDocument

  alias Meadow.IIIF
  alias Meadow.Utils.Exif, as: ExifUtil

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
            label: file_set.metadata.label,
            exif: ExifUtil.index(file_set.metadata.exif)
          }
        end),
      id: work.id,
      iiifManifest: IIIF.manifest_id(work.id),
      model: %{application: "Meadow", name: "Image"},
      modifiedDate: work.updated_at,
      project: format(work.project),
      published: work.published,
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
  end

  defp format(%{id: id, title: title}), do: %{id: id, title: title}
  defp format(%{id: _id, label: _label, scheme: _scheme} = field), do: field
  defp format(_), do: %{}
end
