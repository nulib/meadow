defmodule Meadow.AI.Provenance.Schemas.Event do
  @moduledoc "Append-only event in an AI provenance target lifecycle."

  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.AI.Provenance.Schemas.{EventAgent, Target}

  @event_types ~w(
    proposed
    human_edited
    human_replaced
    approved
    rejected
    applied
    deleted
    failed
    legacy_note_migrated
  )

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "ai_activity_events" do
    field(:event_type, :string)
    field(:actor, :string)
    field(:occurred_at, :utc_datetime_usec)
    field(:value_before, :map)
    field(:value_after, :map)
    field(:notes, :string)
    field(:premis_event_type, :string)
    field(:outcome, :string)
    field(:outcome_detail, :string)
    field(:c2pa_action, :string)
    field(:c2pa_assertion_label, :string)

    belongs_to(:target, Target, foreign_key: :activity_target_id)
    has_many(:agent_links, EventAgent, foreign_key: :activity_event_id)

    timestamps()
  end

  def changeset(event \\ %__MODULE__{}, attrs) do
    event
    |> cast(attrs, [
      :activity_target_id,
      :event_type,
      :actor,
      :occurred_at,
      :value_before,
      :value_after,
      :notes,
      :premis_event_type,
      :outcome,
      :outcome_detail,
      :c2pa_action,
      :c2pa_assertion_label
    ])
    |> put_default_occurred_at()
    |> validate_required([:activity_target_id, :event_type, :occurred_at])
    |> validate_inclusion(:event_type, @event_types)
    |> assoc_constraint(:target)
  end

  defp put_default_occurred_at(changeset) do
    case get_field(changeset, :occurred_at) do
      nil -> put_change(changeset, :occurred_at, DateTime.utc_now())
      _ -> changeset
    end
  end
end
