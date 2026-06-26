defmodule Meadow.AI.Provenance.Schemas.Target do
  @moduledoc "A field or object affected by an AI provenance activity."

  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.AI.Provenance.Schemas.{Activity, Event}

  @origins ~w(
    ai_generated
    ai_modified_human_content
    ai_assisted_human_modified
    human_replacement_after_ai_suggestion
    human_attested_after_ai
    human_generated
    legacy_ai_note_detected
    human_or_legacy
  )

  @statuses ~w(proposed reviewed applied rejected failed deleted legacy)

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "ai_activity_targets" do
    field(:target_type, :string)
    field(:target_id, :string)
    field(:field_path, :string)
    field(:operation, :string)
    field(:source_value_snapshot, :map)
    field(:proposed_value, :map)
    field(:origin, :string)
    field(:status, :string, default: "proposed")
    field(:premis_object_category, :string)
    field(:object_identifier_type, :string)
    field(:object_identifier_value, :string)
    field(:access_link, :string)
    field(:restricted, :boolean, default: false)
    field(:content_hash, :string)
    field(:content_hash_algorithm, :string)
    field(:c2pa_action, :string)
    field(:digital_source_type_uri, :string)
    field(:ingredient_relationship, :string)
    field(:human_oversight_level, :string)
    field(:c2pa_assertion_label, :string)
    field(:c2pa_manifest_id, :string)
    field(:c2pa_claim_id, :string)
    field(:c2pa_validation_status, :string)
    field(:c2pa_signature_status, :string)

    belongs_to(:activity, Activity, foreign_key: :activity_id)
    has_many(:events, Event, foreign_key: :activity_target_id)

    timestamps()
  end

  def changeset(target \\ %__MODULE__{}, attrs) do
    target
    |> cast(attrs, [
      :activity_id,
      :target_type,
      :target_id,
      :field_path,
      :operation,
      :source_value_snapshot,
      :proposed_value,
      :origin,
      :status,
      :premis_object_category,
      :object_identifier_type,
      :object_identifier_value,
      :access_link,
      :restricted,
      :content_hash,
      :content_hash_algorithm,
      :c2pa_action,
      :digital_source_type_uri,
      :ingredient_relationship,
      :human_oversight_level,
      :c2pa_assertion_label,
      :c2pa_manifest_id,
      :c2pa_claim_id,
      :c2pa_validation_status,
      :c2pa_signature_status
    ])
    |> validate_required([:activity_id, :target_type, :target_id, :field_path, :origin, :status])
    |> validate_inclusion(:origin, @origins)
    |> validate_inclusion(:status, @statuses)
    |> assoc_constraint(:activity)
  end

  def origins, do: @origins
end
