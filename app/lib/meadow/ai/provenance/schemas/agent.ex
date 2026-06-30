defmodule Meadow.AI.Provenance.Schemas.Agent do
  @moduledoc "Human, organization, software, or model agent involved in AI provenance events."

  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.AI.Provenance.Schemas.EventAgent

  @agent_types ~w(human organization software model service signer)

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @foreign_key_type Ecto.UUID
  @timestamps_opts [type: :utc_datetime_usec]
  schema "ai_agents" do
    field(:agent_type, :string)
    field(:name, :string)
    field(:identifier_type, :string)
    field(:identifier_value, :string)
    field(:version, :string)
    field(:metadata, :map)

    has_many(:event_links, EventAgent, foreign_key: :agent_id)

    timestamps()
  end

  def changeset(agent \\ %__MODULE__{}, attrs) do
    agent
    |> cast(attrs, [
      :agent_type,
      :name,
      :identifier_type,
      :identifier_value,
      :version,
      :metadata
    ])
    |> validate_required([:agent_type, :name])
    |> validate_inclusion(:agent_type, @agent_types)
  end

  def agent_types, do: @agent_types
end
