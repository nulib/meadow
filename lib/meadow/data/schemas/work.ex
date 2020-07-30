defmodule Meadow.Data.Schemas.Work do
  @moduledoc """
  A repository data object. Embeds one Metadata map and many FileSets.
  """

  use Ecto.Schema
  alias Meadow.Data.Schemas.ActionState
  alias Meadow.Data.Schemas.Collection
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Data.Schemas.WorkAdministrativeMetadata
  alias Meadow.Data.Schemas.WorkDescriptiveMetadata
  alias Meadow.Data.Types
  alias Meadow.IIIF
  alias Meadow.Ingest.Schemas.Sheet

  import Ecto.Changeset
  import Ecto.Query, warn: false
  import Meadow.Data.Schemas.Validations

  use Meadow.Constants

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "works" do
    field(:accession_number, :string)
    field(:published, :boolean, default: false)
    field(:representative_file_set_id, Ecto.UUID, default: nil)
    field(:visibility, Types.CodedTerm)
    field(:work_type, Types.CodedTerm)

    timestamps()

    embeds_one(:descriptive_metadata, WorkDescriptiveMetadata, on_replace: :update)
    embeds_one(:administrative_metadata, WorkAdministrativeMetadata, on_replace: :update)

    has_many(:file_sets, FileSet)

    has_many(:action_states, ActionState,
      references: :id,
      foreign_key: :object_id,
      on_delete: :delete_all
    )

    belongs_to(:collection, Collection)

    belongs_to(:ingest_sheet, Sheet)
    has_one(:project, through: [:ingest_sheet, :project])

    field(:representative_image, :string, virtual: true, default: nil)
  end

  def changeset(work, attrs) do
    required_params = [:accession_number]

    optional_params = [
      :collection_id,
      :representative_file_set_id,
      :ingest_sheet_id,
      :visibility,
      :work_type
    ]

    work
    |> cast(attrs, required_params ++ optional_params)
    |> prepare_embed(:administrative_metadata)
    |> prepare_embed(:descriptive_metadata)
    |> cast_embed(:administrative_metadata)
    |> cast_embed(:descriptive_metadata)
    |> cast_assoc(:file_sets)
    |> assoc_constraint(:collection)
    |> validate_required(required_params)
    |> unique_constraint(:accession_number)
  end

  def update_changeset(work, attrs) do
    allowed_params = [
      :collection_id,
      :ingest_sheet_id,
      :published,
      :representative_file_set_id,
      :visibility
    ]

    work
    |> cast(attrs, allowed_params)
    |> prepare_embed(:administrative_metadata)
    |> prepare_embed(:descriptive_metadata)
    |> cast_embed(:administrative_metadata)
    |> cast_embed(:descriptive_metadata)
    |> assoc_constraint(:collection)
  end

  defimpl Elasticsearch.Document, for: Meadow.Data.Schemas.Work do
    alias Elasticsearch.Document.Meadow.Data.Schemas.WorkAdministrativeMetadata,
      as: AdministrativeMetadataDocument

    alias Elasticsearch.Document.Meadow.Data.Schemas.WorkDescriptiveMetadata,
      as: DescriptiveMetadataDocument

    def id(work), do: work.id
    def routing(_), do: false

    def encode(work) do
      %{
        accessionNumber: work.accession_number,
        collection: format(work.collection),
        createDate: work.inserted_at,
        fileSets:
          work.file_sets
          |> Enum.map(fn file_set ->
            %{
              id: file_set.id,
              accessionNumber: file_set.accession_number,
              label: file_set.metadata.label
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
end
