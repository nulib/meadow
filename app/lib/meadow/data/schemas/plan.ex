defmodule Meadow.Data.Schemas.Plan do
  @moduledoc """
  Plan stores high-level AI agent tasks for modifying Meadow data.

  A Plan represents the overall task given to an AI agent (e.g., "Translate titles to Spanish"
  or "Look up and assign LCNAF contributors"), while individual work-specific changes are stored
  in associated PlanChange records.

  ## Example Workflow

  1. User provides a prompt: "Translate the titles to Spanish in the alternate_title field"
  2. Agent processes each work, using tools (translation APIs, etc.) to generate specific changes
  3. System creates:
     - One Plan record with the prompt and work selection criteria
     - Multiple PlanChange records, one per work, with work-specific modifications

  ## Fields

  - `prompt` - The natural language instruction given to the agent
    Example: "Add a date_created EDTF string for the work based on the work's existing description, creator, and temporal subjects"

  - `query` - OpenSearch query string identifying works
    Example: `"collection.id:abc-123"` or `"id:(73293ebf-288b-4d4f-8843-488391796fea OR 2a27f163-c7fd-437c-8d4d-c2dbce72c884)"`

  - `status` - Current state of the plan:
    - `:pending` - Plan created, proposing changes
    - `:proposed` - Changes created, awaiting review
    - `:approved` - Plan approved, will be completed
    - `:rejected` - Plan rejected, will not be completed
    - `:completed` - All approved changes have been completed
    - `:error` - Execution failed

  - `user` - User who approved/completed the plan
  - `notes` - Optional notes about approval/rejection
  - `completed_at` - When the plan was completed
  - `error` - Error message if application failed
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Meadow.Data.Schemas.PlanChange

  @statuses [:pending, :proposed, :approved, :rejected, :completed, :error]

  @derive {JSON.Encoder, except: [:plan_changes, :__meta__]}
  @primary_key {:id, Ecto.UUID, autogenerate: false, read_after_writes: true}
  @timestamps_opts [type: :utc_datetime_usec]
  schema "plans" do
    field(:prompt, :string)
    field(:query, :string)
    field(:status, Ecto.Enum, values: @statuses, default: :pending)
    field(:user, :string)
    field(:notes, :string)
    field(:completed_at, :utc_datetime_usec)
    field(:error, :string)

    has_many(:plan_changes, PlanChange, foreign_key: :plan_id)

    timestamps()
  end

  @doc false
  def changeset(plan, attrs) do
    plan
    |> cast(attrs, [:prompt, :query, :status, :user, :notes, :completed_at, :error])
    |> validate_required([:prompt])
    |> validate_inclusion(:status, @statuses)
  end

  @doc """
  Transition plan to approved status

  ## Example

      iex> plan |> Plan.approve("user@example.com") |> Repo.update()
      {:ok, %Plan{status: :approved, user: "user@example.com"}}
  """
  def approve(plan, user \\ nil) do
    plan
    |> cast(%{status: :approved, user: user}, [:status, :user])
    |> validate_inclusion(:status, @statuses)
  end

  @doc """
  Transition plan to rejected status

  ## Example

      iex> plan |> Plan.reject("Changes not needed") |> Repo.update()
      {:ok, %Plan{status: :rejected, notes: "Changes not needed"}}
  """
  def reject(plan, notes \\ nil) do
    plan
    |> cast(%{status: :rejected, notes: notes}, [:status, :notes])
    |> validate_inclusion(:status, @statuses)
  end

  @doc """
  Mark plan as completed

  ## Example

      iex> plan |> Plan.mark_completed() |> Repo.update()
      {:ok, %Plan{status: :completed, completed_at: ~U[2025-10-01 12:00:00.000000Z]}}
  """
  def mark_completed(plan) do
    plan
    |> cast(%{status: :completed, completed_at: DateTime.utc_now()}, [:status, :completed_at])
    |> validate_inclusion(:status, @statuses)
  end

  @doc """
  Mark plan as failed with error

  ## Example

      iex> plan |> Plan.mark_error("Database connection failed") |> Repo.update()
      {:ok, %Plan{status: :error, error: "Database connection failed"}}
  """
  def mark_error(plan, error) do
    plan
    |> cast(%{status: :error, error: error}, [:status, :error])
    |> validate_inclusion(:status, @statuses)
  end
end
