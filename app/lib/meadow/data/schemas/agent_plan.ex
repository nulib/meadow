defmodule Meadow.Data.Schemas.AgentPlan do
  @moduledoc """
  AgentPlan stores structured plans created by AI agents for modifying Meadow data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @statuses [:pending, :approved, :rejected, :executed, :error]

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "agent_plans" do
    field :query, :string
    field :changeset, :map
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :user, :string
    field :notes, :string
    field :executed_at, :utc_datetime_usec
    field :error, :string
    timestamps()
  end

  @doc false
  def changeset(agent_plan, attrs) do
    agent_plan
    |> cast(attrs, [:query, :changeset, :status, :user, :notes, :executed_at, :error])
    |> validate_required([:query, :changeset])
    |> validate_inclusion(:status, @statuses)
    |> validate_changeset_format()
  end

  @doc """
  Transition plan to approved status
  """
  def approve(agent_plan, user \\ nil) do
    agent_plan
    |> cast(%{status: :approved, user: user}, [:status, :user])
    |> validate_inclusion(:status, @statuses)
  end

  @doc """
  Transition plan to rejected status
  """
  def reject(agent_plan, notes \\ nil) do
    agent_plan
    |> cast(%{status: :rejected, notes: notes}, [:status, :notes])
    |> validate_inclusion(:status, @statuses)
  end

  @doc """
  Mark plan as executed
  """
  def mark_executed(agent_plan) do
    agent_plan
    |> cast(%{status: :executed, executed_at: DateTime.utc_now()}, [:status, :executed_at])
    |> validate_inclusion(:status, @statuses)
  end

  @doc """
  Mark plan as failed with error
  """
  def mark_error(agent_plan, error) do
    agent_plan
    |> cast(%{status: :error, error: error}, [:status, :error])
    |> validate_inclusion(:status, @statuses)
  end

  defp validate_changeset_format(changeset) do
    case get_field(changeset, :changeset) do
      nil ->
        changeset

      cs when is_map(cs) ->
        changeset

      _ ->
        add_error(changeset, :changeset, "must be a map/object")
    end
  end
end
