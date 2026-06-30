defmodule Meadow.AI.Provenance.Schemas.Source do
  @moduledoc "Source evidence for an AI provenance activity."

  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.AI.Provenance.Schemas.Activity

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "ai_activity_sources" do
    field(:collection_id, Ecto.UUID)
    field(:collection_title, :string)
    field(:item_id, :string)
    field(:item_type, :string)
    field(:work_id, Ecto.UUID)
    field(:file_set_id, Ecto.UUID)
    field(:pointer, :map)
    field(:holding_organization, :string)
    field(:access_link, :string)
    field(:restricted, :boolean, default: false)
    field(:source_snapshot, :map)
    field(:premis_object_category, :string)
    field(:object_identifier_type, :string)
    field(:object_identifier_value, :string)
    field(:content_hash, :string)
    field(:content_hash_algorithm, :string)
    field(:relationship_role, :string)
    field(:ingredient_relationship, :string)
    field(:c2pa_manifest_id, :string)
    field(:c2pa_claim_id, :string)

    belongs_to(:activity, Activity, foreign_key: :activity_id)

    timestamps()
  end

  def changeset(source \\ %__MODULE__{}, attrs) do
    source
    |> cast(attrs, [
      :activity_id,
      :collection_id,
      :collection_title,
      :item_id,
      :item_type,
      :work_id,
      :file_set_id,
      :pointer,
      :holding_organization,
      :access_link,
      :restricted,
      :source_snapshot,
      :premis_object_category,
      :object_identifier_type,
      :object_identifier_value,
      :content_hash,
      :content_hash_algorithm,
      :relationship_role,
      :ingredient_relationship,
      :c2pa_manifest_id,
      :c2pa_claim_id
    ])
    |> validate_required([:activity_id])
    |> assoc_constraint(:activity)
  end
end
