defmodule Meadow.Data.Planner do
  @moduledoc """
  The Planner context for managing AI agent plans.
  """
  import Ecto.Query, warn: false
  alias Meadow.Data.Schemas.AgentPlan
  alias Meadow.Repo

  @doc """
  Returns the list of agent plans.

  ## Examples

      iex> list_plans()
      [%AgentPlan{}, ...]

  """
  def list_plans do
    Repo.all(AgentPlan)
  end

  @doc """
  Returns a list of plans matching the given `criteria`.

  Example Criteria:

  [{:limit, 15}, {:status, "pending"}, {:user_id, "user123"}]
  """
  def list_plans(criteria) do
    criteria
    |> plan_query()
    |> Repo.all()
  end

  @doc """
  Returns a composable query matching the given `criteria`.
  """
  def plan_query(criteria) do
    query = from(AgentPlan)

    Enum.reduce(criteria, query, fn
      {:limit, limit}, query ->
        from(p in query, limit: ^limit)

      {:status, status}, query ->
        from(p in query, where: p.status == ^status)

      {:user, user}, query ->
        from(p in query, where: p.user == ^user)

      {:order, order}, query ->
        from(p in query, order_by: [{^order, :inserted_at}])
    end)
  end

  @doc """
  Gets a single plan.

  Raises `Ecto.NoResultsError` if the AgentPlan does not exist.

  ## Examples

      iex> get_plan!("123")
      %AgentPlan{}

      iex> get_plan!("456")
      ** (Ecto.NoResultsError)

  """
  def get_plan!(id) do
    Repo.get!(AgentPlan, id)
  end

  @doc """
  Gets a single plan.

  Returns `nil` if the AgentPlan does not exist.

  ## Examples

      iex> get_plan("123")
      %AgentPlan{}

      iex> get_plan("456")
      nil

  """
  def get_plan(id) do
    Repo.get(AgentPlan, id)
  end

  @doc """
  Gets pending plans.

  ## Examples

      iex> get_pending_plans()
      [%AgentPlan{status: :pending}, ...]

  """
  def get_pending_plans do
    from(p in AgentPlan, where: p.status == :pending, order_by: [asc: :inserted_at])
    |> Repo.all()
  end

  @doc """
  Gets approved plans ready for execution.

  ## Examples

      iex> get_approved_plans()
      [%AgentPlan{status: :approved}, ...]

  """
  def get_approved_plans do
    from(p in AgentPlan, where: p.status == :approved, order_by: [asc: :inserted_at])
    |> Repo.all()
  end

  @doc """
  Creates a plan.

  ## Examples

      iex> create_plan(%{query: "...", changeset: %{}})
      {:ok, %AgentPlan{}}

      iex> create_plan(%{query: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_plan(attrs \\ %{}) do
    %AgentPlan{}
    |> AgentPlan.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Same as create_plan/1 but raises on error.
  """
  def create_plan!(attrs \\ %{}) do
    %AgentPlan{}
    |> AgentPlan.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Updates a plan.

  ## Examples

      iex> update_plan(plan, %{notes: "Updated notes"})
      {:ok, %AgentPlan{}}

      iex> update_plan(plan, %{status: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def update_plan(%AgentPlan{} = plan, attrs) do
    plan
    |> AgentPlan.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Approves a plan.

  ## Examples

      iex> approve_plan(plan, "user123")
      {:ok, %AgentPlan{status: :approved}}

  """
  def approve_plan(%AgentPlan{} = plan, user \\ nil) do
    plan
    |> AgentPlan.approve(user)
    |> Repo.update()
  end

  @doc """
  Rejects a plan.

  ## Examples

      iex> reject_plan(plan, "Not appropriate")
      {:ok, %AgentPlan{status: :rejected}}

  """
  def reject_plan(%AgentPlan{} = plan, notes \\ nil) do
    plan
    |> AgentPlan.reject(notes)
    |> Repo.update()
  end

  @doc """
  Marks a plan as executed.

  ## Examples

      iex> mark_plan_executed(plan)
      {:ok, %AgentPlan{status: :executed}}

  """
  def mark_plan_executed(%AgentPlan{} = plan) do
    plan
    |> AgentPlan.mark_executed()
    |> Repo.update()
  end

  @doc """
  Marks a plan as failed with an error.

  ## Examples

      iex> mark_plan_error(plan, "Failed to apply changeset")
      {:ok, %AgentPlan{status: :error}}

  """
  def mark_plan_error(%AgentPlan{} = plan, error) do
    plan
    |> AgentPlan.mark_error(error)
    |> Repo.update()
  end

  @doc """
  Deletes a plan.

  ## Examples

      iex> delete_plan(plan)
      {:ok, %AgentPlan{}}

      iex> delete_plan(plan)
      {:error, %Ecto.Changeset{}}

  """
  def delete_plan(%AgentPlan{} = plan) do
    Repo.delete(plan)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking plan changes.

  ## Examples

      iex> change_plan(plan)
      %Ecto.Changeset{data: %AgentPlan{}}

  """
  def change_plan(%AgentPlan{} = plan, attrs \\ %{}) do
    AgentPlan.changeset(plan, attrs)
  end
end
