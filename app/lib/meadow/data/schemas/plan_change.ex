defmodule Meadow.Data.Schemas.PlanChange do
  @moduledoc """
  PlanChange stores individual work-specific modifications proposed by an AI agent.

  Each PlanChange represents a single work's proposed modifications as part of a larger Plan.
  The agent examines each work in context and generates tailored changes.

  ## Example Scenarios

  ### Scenario 1: Adding EDTF Date Strings
  Plan prompt: "Add a date_created EDTF string for the work based on the work's existing description, creator, and temporal subjects"

  Generated PlanChanges:
  - Work A (description mentions "November 10, 1896"):
    `changeset: %{descriptive_metadata: %{date_created: ["1896-11-10"]}}`
  - Work B (temporal subject shows "1920s"):
    `changeset: %{descriptive_metadata: %{date_created: ["192X"]}}`

  ### Scenario 2: Looking Up and Assigning Contributors
  Plan prompt: "Look up LCNAF names from description and assign as contributors with MARC relators"

  Generated PlanChanges:
  - Work A (description mentions "photographed by Ansel Adams"):
    `changeset: %{descriptive_metadata: %{contributor: [%{term: "Adams, Ansel, 1902-1984", role: %{id: "pht", scheme: "marc_relator"}}]}}`
  - Work B (description mentions "interviewed by Studs Terkel"):
    `changeset: %{descriptive_metadata: %{contributor: [%{term: "Terkel, Studs, 1912-2008", role: %{id: "ivr", scheme: "marc_relator"}}]}}`

  ## Fields

  - `plan_id` - Foreign key to the parent Plan
  - `work_id` - The specific work being modified
  - `changeset` - Map of field changes specific to this work
    Structure matches Meadow.Data.Schemas.Work field structure

  - `status` - Current state of this change:
    - `:pending` - Change proposed, awaiting review
    - `:approved` - Change approved for execution
    - `:rejected` - Change rejected, will not be executed
    - `:executed` - Change has been applied to the work
    - `:error` - Execution failed for this change

  - `user` - User who approved/rejected this specific change
  - `notes` - Optional notes about this change (e.g., reason for rejection)
  - `executed_at` - When this change was applied
  - `error` - Error message if this change failed to apply
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.Data.Schemas.Plan

  @statuses [:pending, :approved, :rejected, :executed, :error]

  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "plan_changes" do
    field :plan_id, Ecto.UUID
    field :work_id, Ecto.UUID
    field :changeset, :map
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :user, :string
    field :notes, :string
    field :executed_at, :utc_datetime_usec
    field :error, :string

    belongs_to :plan, Plan, foreign_key: :plan_id, references: :id, define_field: false

    timestamps()
  end

  @doc false
  def changeset(plan_change, attrs) do
    plan_change
    |> cast(attrs, [:plan_id, :work_id, :changeset, :status, :user, :notes, :executed_at, :error])
    |> validate_required([:work_id, :changeset])
    |> validate_inclusion(:status, @statuses)
    |> validate_changeset_format()
    |> foreign_key_constraint(:plan_id)
  end

  @doc """
  Transition change to approved status

  ## Example

      iex> change |> PlanChange.approve("user@example.com") |> Repo.update()
      {:ok, %PlanChange{status: :approved, user: "user@example.com"}}
  """
  def approve(plan_change, user \\ nil) do
    plan_change
    |> cast(%{status: :approved, user: user}, [:status, :user])
    |> validate_inclusion(:status, @statuses)
  end

  @doc """
  Transition change to rejected status

  ## Example

      iex> change |> PlanChange.reject("Translation is incorrect") |> Repo.update()
      {:ok, %PlanChange{status: :rejected, notes: "Translation is incorrect"}}
  """
  def reject(plan_change, notes \\ nil) do
    plan_change
    |> cast(%{status: :rejected, notes: notes}, [:status, :notes])
    |> validate_inclusion(:status, @statuses)
  end

  @doc """
  Mark change as executed

  ## Example

      iex> change |> PlanChange.mark_executed() |> Repo.update()
      {:ok, %PlanChange{status: :executed, executed_at: ~U[2025-10-01 12:00:00.000000Z]}}
  """
  def mark_executed(plan_change) do
    plan_change
    |> cast(%{status: :executed, executed_at: DateTime.utc_now()}, [:status, :executed_at])
    |> validate_inclusion(:status, @statuses)
  end

  @doc """
  Mark change as failed with error

  ## Example

      iex> change |> PlanChange.mark_error("Work not found") |> Repo.update()
      {:ok, %PlanChange{status: :error, error: "Work not found"}}
  """
  def mark_error(plan_change, error) do
    plan_change
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
