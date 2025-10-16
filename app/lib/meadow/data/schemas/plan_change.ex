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
    `add: %{descriptive_metadata: %{date_created: ["1896-11-10"]}}`
  - Work B (temporal subject shows "1920s"):
    `add: %{descriptive_metadata: %{date_created: ["192X"]}}`

  ### Scenario 2: Looking Up and Assigning Contributors
  Plan prompt: "Look up LCNAF names from description and assign as contributors with MARC relators"

  Generated PlanChanges:
  - Work A (description mentions "photographed by Ansel Adams"):
    `add: %{descriptive_metadata: %{contributor: [%{term: "Adams, Ansel, 1902-1984", role: %{id: "pht", scheme: "marc_relator"}}]}}`
  - Work B (description mentions "interviewed by Studs Terkel"):
    `add: %{descriptive_metadata: %{contributor: [%{term: "Terkel, Studs, 1912-2008", role: %{id: "ivr", scheme: "marc_relator"}}]}}`

  ### Scenario 3: Removing Extraneous Subject Headings
  Plan prompt: "Remove extraneous subject headings like 'Photograph' and 'Image'"

  Generated PlanChanges:
  - Work A has generic subjects to remove:
    `delete: %{descriptive_metadata: %{subject: [%{term: "Photograph"}, %{term: "Image"}]}}`

  ## Fields

  - `plan_id` - Foreign key to the parent Plan
  - `work_id` - The specific work being modified
  - `add` - Map of values to append to existing work data
  - `delete` - Map of values to remove from existing work data
  - `replace` - Map of values to fully replace in work data

  - `status` - Current state of this change:
    - `:pending` - Change created, no proposed updates yet
    - `:proposed` - Change proposed, awaiting review
    - `:approved` - Change approved, will be completed
    - `:rejected` - Change rejected, will not be completed
    - `:completed` - Change has been completed to the work
    - `:error` - Execution failed for this change

  - `user` - User who approved/rejected this specific change
  - `notes` - Optional notes about this change (e.g., reason for rejection)
  - `completed_at` - When this change was completed
  - `error` - Error message if this change failed to apply
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.Data.Schemas.Plan

  @statuses [:pending, :proposed, :approved, :rejected, :completed, :error]

  @derive {JSON.Encoder, except: [:plan, :__meta__]}
  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "plan_changes" do
    field(:plan_id, Ecto.UUID)
    field(:work_id, Ecto.UUID)
    field(:add, :map)
    field(:delete, :map)
    field(:replace, :map)
    field(:status, Ecto.Enum, values: @statuses, default: :pending)
    field(:user, :string)
    field(:notes, :string)
    field(:completed_at, :utc_datetime_usec)
    field(:error, :string)

    belongs_to(:plan, Plan, foreign_key: :plan_id, references: :id, define_field: false)

    timestamps()
  end

  @doc false
  def changeset(plan_change, attrs) do
    plan_change
    |> cast(attrs, [
      :plan_id,
      :work_id,
      :add,
      :delete,
      :replace,
      :status,
      :user,
      :notes,
      :completed_at,
      :error
    ])
    |> validate_required([:work_id])
    |> validate_at_least_one_operation()
    |> validate_inclusion(:status, @statuses)
    |> validate_map_format(:add)
    |> validate_map_format(:delete)
    |> validate_map_format(:replace)
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
  Mark change as completed

  ## Example

      iex> change |> PlanChange.mark_completed() |> Repo.update()
      {:ok, %PlanChange{status: :completed, completed_at: ~U[2025-10-01 12:00:00.000000Z]}}
  """
  def mark_completed(plan_change) do
    plan_change
    |> cast(%{status: :completed, completed_at: DateTime.utc_now()}, [:status, :completed_at])
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

  defp validate_at_least_one_operation(changeset) do
    add = get_field(changeset, :add)
    delete = get_field(changeset, :delete)
    replace = get_field(changeset, :replace)

    if is_nil(add) and is_nil(delete) and is_nil(replace) do
      add_error(changeset, :add, "at least one of add, delete, or replace must be specified")
    else
      changeset
    end
  end

  defp validate_map_format(changeset, field) do
    case get_field(changeset, field) do
      nil ->
        changeset

      value when is_map(value) ->
        changeset

      _ ->
        add_error(changeset, field, "must be a map/object")
    end
  end
end
