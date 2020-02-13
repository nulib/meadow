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

  import Ecto.Changeset

  use Meadow.Constants

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "works" do
    field :accession_number, :string
    field :visibility, :string
    field :work_type, :string
    field :published, :boolean, default: false
    timestamps()

    embeds_one :descriptive_metadata, WorkDescriptiveMetadata, on_replace: :update
    embeds_one :administrative_metadata, WorkAdministrativeMetadata, on_replace: :update

    has_many :file_sets, FileSet

    has_many :action_states, ActionState,
      references: :id,
      foreign_key: :object_id,
      on_delete: :delete_all

    belongs_to :collection, Collection
  end

  def changeset(work, attrs) do
    required_params = [:accession_number, :visibility, :work_type]
    optional_params = [:collection_id]

    work
    |> cast(attrs, required_params ++ optional_params)
    |> cast_embed(:administrative_metadata)
    |> cast_embed(:descriptive_metadata)
    |> cast_assoc(:file_sets)
    |> assoc_constraint(:collection)
    |> validate_required(required_params)
    |> validate_inclusion(:visibility, @visibility)
    |> validate_inclusion(:work_type, @work_types)
    |> unique_constraint(:accession_number)
  end

  defimpl Elasticsearch.Document, for: Meadow.Data.Schemas.Work do
    def id(work), do: work.id
    def routing(_), do: false

    def encode(work) do
      %{
        model: %{application: "Meadow", name: String.capitalize(work.work_type)},
        title: work.descriptive_metadata.title,
        accession_number: work.accession_number,
        description: work.descriptive_metadata.description,
        visibility: work.visibility,
        published: work.published,
        collection:
          case work.collection do
            nil -> %{}
            collection -> %{id: collection.id, title: collection.name}
          end,
        create_date: work.inserted_at,
        modified_date: work.updated_at
      }
    end
  end
end
