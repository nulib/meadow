defmodule Meadow.AI.Provenance.Schemas.EventAgent do
  @moduledoc "Role-bearing link between a provenance event and an agent."

  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.AI.Provenance.Schemas.{Agent, Event}

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "ai_activity_event_agents" do
    field(:role, :string)

    belongs_to(:event, Event, foreign_key: :activity_event_id)
    belongs_to(:agent, Agent, foreign_key: :agent_id)

    timestamps()
  end

  def changeset(event_agent \\ %__MODULE__{}, attrs) do
    event_agent
    |> cast(attrs, [:activity_event_id, :agent_id, :role])
    |> validate_required([:activity_event_id, :agent_id, :role])
    |> assoc_constraint(:event)
    |> assoc_constraint(:agent)
    |> unique_constraint([:activity_event_id, :agent_id, :role],
      name: :ai_activity_event_agents_activity_event_id_agent_id_role_index
    )
  end
end
