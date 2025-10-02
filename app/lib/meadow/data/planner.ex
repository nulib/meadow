defmodule Meadow.Data.Planner do
  @moduledoc """
  The Planner context for managing AI agent plans and their proposed changes.

  ## Workflow Overview

  1. **Create Plan**: Create a plan with a prompt and query. PlanChanges are automatically
     populated from the query results. Supports simple query strings or JSON queries.
     ```
     # Simple query string
     {:ok, plan} = create_plan(%{
       prompt: "Add date_created EDTF strings based on work metadata",
       query: "collection.id:abc-123"
     })

     # Or with JSON query
     {:ok, plan} = create_plan(%{
       prompt: "Add date_created EDTF strings based on work metadata",
       query: ~s({"query": {"match": {"collection.id": "abc-123"}}})
     })
     # Plan now has PlanChanges for each work in the query results
     ```

  2. **Update Changes**: Agent updates the changeset for each PlanChange
     ```
     changes = list_plan_changes(plan.id)
     Enum.each(changes, fn change ->
       case update_plan_change(change, %{
         changeset: %{descriptive_metadata: %{date_created: ["1896-11-10"]}}
       }) do
         {:ok, _updated_change} -> :ok
         {:error, message} -> Logger.error("Error: " <> message)
       end
     end)
     ```

  3. **Review**: User reviews and approves/rejects plan and individual changes
     ```
     approve_plan(plan, "user@example.com")
     approve_plan_change(change, "user@example.com")
     ```

  4. **Execute**: Apply approved changes to works
     ```
     execute_plan(plan)
     ```
  """
  import Ecto.Query, warn: false
  alias Meadow.Data.Schemas.{Plan, PlanChange}
  alias Meadow.Data.Schemas.Work
  alias Meadow.Repo
  alias Meadow.Utils.ChangesetErrors

  @doc """
  Returns the list of plans.

  ## Examples

      iex> list_plans()
      [%Plan{}, ...]
  """
  def list_plans do
    Repo.all(Plan)
  end

  @doc """
  Returns a list of plans matching the given criteria.

  ## Example Criteria

      [{:limit, 15}, {:status, :pending}, {:user, "user@example.com"}]

  ## Examples

      iex> list_plans([status: :pending])
      [%Plan{status: :pending}, ...]
  """
  def list_plans(criteria) do
    criteria
    |> plan_query()
    |> Repo.all()
  end

  @doc """
  Returns a composable query matching the given criteria.

  ## Examples

      iex> plan_query([status: :pending]) |> Repo.all()
      [%Plan{status: :pending}, ...]
  """
  def plan_query(criteria) do
    query = from(Plan)

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

  Raises `Ecto.NoResultsError` if the Plan does not exist.

  ## Examples

      iex> get_plan!("123")
      %Plan{}

      iex> get_plan!("456")
      ** (Ecto.NoResultsError)
  """
  def get_plan!(id, opts \\ []) do
    query = from(p in Plan, where: p.id == ^id)

    query =
      if opts[:preload_changes] do
        from(p in query, preload: :plan_changes)
      else
        query
      end

    Repo.one!(query)
  end

  @doc """
  Gets a single plan.

  Returns `nil` if the Plan does not exist.

  ## Examples

      iex> get_plan("123")
      %Plan{}

      iex> get_plan("456")
      nil
  """
  def get_plan(id, opts \\ []) do
    query = from(p in Plan, where: p.id == ^id)

    query =
      if opts[:preload_changes] do
        from(p in query, preload: :plan_changes)
      else
        query
      end

    Repo.one(query)
  end

  @doc """
  Gets pending plans.

  ## Examples

      iex> get_pending_plans()
      [%Plan{status: :pending}, ...]
  """
  def get_pending_plans(opts \\ []) do
    query = from(p in Plan, where: p.status == :pending, order_by: [asc: :inserted_at])

    query =
      if opts[:preload_changes] do
        from(p in query, preload: :plan_changes)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets approved plans ready for execution.

  ## Examples

      iex> get_approved_plans()
      [%Plan{status: :approved}, ...]
  """
  def get_approved_plans(opts \\ []) do
    query = from(p in Plan, where: p.status == :approved, order_by: [asc: :inserted_at])

    query =
      if opts[:preload_changes] do
        from(p in query, preload: :plan_changes)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Creates a plan and automatically populates PlanChanges from the query results.

  ## Examples

      # With OpenSearch query string
      iex> create_plan(%{
      ...>   prompt: "Translate titles to Spanish",
      ...>   query: "collection.id:abc-123"
      ...> })
      {:ok, %Plan{}}

      # With specific work IDs
      iex> create_plan(%{
      ...>   prompt: "Look up LCNAF contributors",
      ...>   query: "id:(work-1 OR work-2 OR work-3)"
      ...> })
      {:ok, %Plan{}}

      iex> create_plan(%{prompt: nil})
      {:error, %Ecto.Changeset{}}
  """
  def create_plan(attrs \\ %{}) do
    changeset = Plan.changeset(%Plan{}, attrs)

    changeset
    |> validate_and_create_plan(attrs)
  end

  defp validate_and_create_plan(%Ecto.Changeset{valid?: false} = changeset, _attrs) do
    {:error, changeset}
  end

  defp validate_and_create_plan(changeset, %{query: query} = _attrs) when is_binary(query) do
    Repo.transaction(fn ->
      plan = Repo.insert!(changeset)
      populate_plan_changes(plan, query)
    end)
  end

  defp validate_and_create_plan(changeset, _attrs) do
    Repo.transaction(fn ->
      Repo.insert!(changeset)
    end)
  end

  @doc """
  Same as create_plan/1 but raises on error.
  """
  def create_plan!(attrs \\ %{}) do
    case create_plan(attrs) do
      {:ok, plan} -> plan
      {:error, changeset} -> raise Ecto.InvalidChangesetError, action: :insert, changeset: changeset
    end
  end

  @doc """
  Updates a plan.

  ## Examples

      iex> update_plan(plan, %{notes: "Updated notes"})
      {:ok, %Plan{}}

      iex> update_plan(plan, %{status: :invalid})
      {:error, %Ecto.Changeset{}}
  """
  def update_plan(%Plan{} = plan, attrs) do
    plan
    |> Plan.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Approves a plan and optionally all its pending changes.

  ## Examples

      iex> approve_plan(plan, "user@example.com")
      {:ok, %Plan{status: :approved, user: "user@example.com"}}

      iex> approve_plan(plan, "user@example.com", approve_changes: true)
      {:ok, %Plan{status: :approved, user: "user@example.com"}}
  """
  def approve_plan(%Plan{} = plan, user \\ nil, opts \\ []) do
    result =
      plan
      |> Plan.approve(user)
      |> Repo.update()

    if opts[:approve_changes] do
      case result do
        {:ok, approved_plan} ->
          # Also approve all pending changes
          from(c in PlanChange,
            where: c.plan_id == ^approved_plan.id and c.status == :pending,
            update: [set: [status: :approved, user: ^user]]
          )
          |> Repo.update_all([])

          {:ok, approved_plan}

        error -> error
      end
    else
      result
    end
  end

  @doc """
  Rejects a plan.

  ## Examples

      iex> reject_plan(plan, "Changes not needed")
      {:ok, %Plan{status: :rejected, notes: "Changes not needed"}}
  """
  def reject_plan(%Plan{} = plan, notes \\ nil) do
    plan
    |> Plan.reject(notes)
    |> Repo.update()
  end

  @doc """
  Marks a plan as executed.

  ## Examples

      iex> mark_plan_executed(plan)
      {:ok, %Plan{status: :executed}}
  """
  def mark_plan_executed(%Plan{} = plan) do
    plan
    |> Plan.mark_executed()
    |> Repo.update()
  end

  @doc """
  Marks a plan as failed with an error.

  ## Examples

      iex> mark_plan_error(plan, "Database connection failed")
      {:ok, %Plan{status: :error, error: "Database connection failed"}}
  """
  def mark_plan_error(%Plan{} = plan, error) do
    plan
    |> Plan.mark_error(error)
    |> Repo.update()
  end

  @doc """
  Deletes a plan and all associated changes.

  ## Examples

      iex> delete_plan(plan)
      {:ok, %Plan{}}

      iex> delete_plan(plan)
      {:error, %Ecto.Changeset{}}
  """
  def delete_plan(%Plan{} = plan) do
    Repo.delete(plan)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking plan changes.

  ## Examples

      iex> change_plan(plan)
      %Ecto.Changeset{data: %Plan{}}
  """
  def change_plan(%Plan{} = plan, attrs \\ %{}) do
    Plan.changeset(plan, attrs)
  end

  # ========== PlanChange Functions ==========

  @doc """
  Returns all changes for a plan.

  ## Examples

      iex> list_plan_changes(plan_id)
      [%PlanChange{}, ...]

      iex> list_plan_changes(plan)
      [%PlanChange{}, ...]
  """
  def list_plan_changes(%Plan{id: plan_id}), do: list_plan_changes(plan_id)

  def list_plan_changes(plan_id) when is_binary(plan_id) do
    from(c in PlanChange, where: c.plan_id == ^plan_id, order_by: [asc: :inserted_at])
    |> Repo.all()
  end

  @doc """
  Returns changes for a plan matching the given criteria.

  ## Example Criteria

      [{:status, :pending}, {:work_id, "work-123"}]

  ## Examples

      iex> list_plan_changes(plan_id, [status: :pending])
      [%PlanChange{status: :pending}, ...]

      iex> list_plan_changes(plan, [status: :pending])
      [%PlanChange{status: :pending}, ...]
  """
  def list_plan_changes(%Plan{id: plan_id}, criteria), do: list_plan_changes(plan_id, criteria)

  def list_plan_changes(plan_id, criteria) when is_binary(plan_id) do
    criteria
    |> Keyword.put(:plan_id, plan_id)
    |> plan_change_query()
    |> Repo.all()
  end

  @doc """
  Returns a composable query matching the given criteria.
  """
  def plan_change_query(criteria) do
    query = from(PlanChange)

    Enum.reduce(criteria, query, fn
      {:plan_id, plan_id}, query ->
        from(c in query, where: c.plan_id == ^plan_id)

      {:work_id, work_id}, query ->
        from(c in query, where: c.work_id == ^work_id)

      {:status, status}, query ->
        from(c in query, where: c.status == ^status)

      {:user, user}, query ->
        from(c in query, where: c.user == ^user)

      {:order, order}, query ->
        from(c in query, order_by: [{^order, :inserted_at}])
    end)
  end

  @doc """
  Gets a single plan change.

  Raises `Ecto.NoResultsError` if the PlanChange does not exist.

  ## Examples

      iex> get_plan_change!("123")
      %PlanChange{}
  """
  def get_plan_change!(id) do
    Repo.get!(PlanChange, id)
  end

  @doc """
  Gets a single plan change.

  Returns `nil` if the PlanChange does not exist.

  ## Examples

      iex> get_plan_change("123")
      %PlanChange{}

      iex> get_plan_change("456")
      nil
  """
  def get_plan_change(id) do
    Repo.get(PlanChange, id)
  end

  @doc """
  Gets a single plan change by plan_id and work_id.

  Returns `nil` if the PlanChange does not exist.

  ## Examples

      iex> get_plan_change_by_work(plan.id, work.id)
      %PlanChange{}

      iex> get_plan_change_by_work(plan, work)
      %PlanChange{}

      iex> get_plan_change_by_work(plan.id, "nonexistent")
      nil
  """
  def get_plan_change_by_work(%Plan{id: plan_id}, work_id), do: get_plan_change_by_work(plan_id, work_id)
  def get_plan_change_by_work(plan_id, %Work{id: work_id}), do: get_plan_change_by_work(plan_id, work_id)
  def get_plan_change_by_work(%Plan{id: plan_id}, %Work{id: work_id}), do: get_plan_change_by_work(plan_id, work_id)

  def get_plan_change_by_work(plan_id, work_id) when is_binary(plan_id) and is_binary(work_id) do
    from(c in PlanChange, where: c.plan_id == ^plan_id and c.work_id == ^work_id)
    |> Repo.one()
  end

  @doc """
  Creates a plan change.

  ## Examples

      iex> create_plan_change(%{
      ...>   plan_id: plan.id,
      ...>   work_id: "work-123",
      ...>   changeset: %{descriptive_metadata: %{date_created: ["1896-11-10"]}}
      ...> })
      {:ok, %PlanChange{}}

      iex> create_plan_change(%{work_id: nil})
      {:error, "can't be blank, can't be blank"}
  """
  def create_plan_change(attrs \\ %{}) do
    changeset = PlanChange.changeset(%PlanChange{}, attrs)

    case Repo.insert(changeset) do
      {:ok, plan_change} ->
        {:ok, plan_change}

      {:error, changeset} ->
        error_message =
          changeset
          |> ChangesetErrors.humanize_errors()
          |> Enum.map_join(", ", fn {_field, error} -> error end)

        {:error, error_message}
    end
  end

  @doc """
  Same as create_plan_change/1 but raises on error.
  """
  def create_plan_change!(attrs \\ %{}) do
    %PlanChange{}
    |> PlanChange.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates multiple plan changes at once.

  ## Examples

      iex> create_plan_changes([
      ...>   %{plan_id: plan.id, work_id: "work-1", changeset: %{...}},
      ...>   %{plan_id: plan.id, work_id: "work-2", changeset: %{...}}
      ...> ])
      {:ok, [%PlanChange{}, %PlanChange{}]}
  """
  def create_plan_changes(changes_attrs) do
    Repo.transaction(fn ->
      Enum.map(changes_attrs, fn attrs ->
        create_plan_change!(attrs)
      end)
    end)
  end

  @doc """
  Updates a plan change.

  ## Examples

      iex> update_plan_change(change, %{notes: "Reviewed"})
      {:ok, %PlanChange{}}

      iex> update_plan_change(change, %{plan_id: "invalid-uuid"})
      {:error, "invalid-uuid is invalid"}
  """
  def update_plan_change(%PlanChange{} = change, attrs) do
    changeset = PlanChange.changeset(change, attrs)

    case Repo.update(changeset) do
      {:ok, updated_change} ->
        {:ok, updated_change}

      {:error, changeset} ->
        error_message =
          changeset
          |> ChangesetErrors.humanize_errors()
          |> Enum.map_join(", ", fn {_field, error} -> error end)

        {:error, error_message}
    end
  end

  @doc """
  Approves a plan change.

  ## Examples

      iex> approve_plan_change(change, "user@example.com")
      {:ok, %PlanChange{status: :approved}}
  """
  def approve_plan_change(%PlanChange{} = change, user \\ nil) do
    change
    |> PlanChange.approve(user)
    |> Repo.update()
  end

  @doc """
  Rejects a plan change.

  ## Examples

      iex> reject_plan_change(change, "Translation incorrect")
      {:ok, %PlanChange{status: :rejected}}
  """
  def reject_plan_change(%PlanChange{} = change, notes \\ nil) do
    change
    |> PlanChange.reject(notes)
    |> Repo.update()
  end

  @doc """
  Marks a plan change as executed.

  ## Examples

      iex> mark_plan_change_executed(change)
      {:ok, %PlanChange{status: :executed}}
  """
  def mark_plan_change_executed(%PlanChange{} = change) do
    change
    |> PlanChange.mark_executed()
    |> Repo.update()
  end

  @doc """
  Marks a plan change as failed with an error.

  ## Examples

      iex> mark_plan_change_error(change, "Work not found")
      {:ok, %PlanChange{status: :error}}
  """
  def mark_plan_change_error(%PlanChange{} = change, error) do
    change
    |> PlanChange.mark_error(error)
    |> Repo.update()
  end

  @doc """
  Deletes a plan change.

  ## Examples

      iex> delete_plan_change(change)
      {:ok, %PlanChange{}}
  """
  def delete_plan_change(%PlanChange{} = change) do
    Repo.delete(change)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking plan change modifications.

  ## Examples

      iex> change_plan_change(change)
      %Ecto.Changeset{data: %PlanChange{}}
  """
  def change_plan_change(%PlanChange{} = change, attrs \\ %{}) do
    PlanChange.changeset(change, attrs)
  end

  @doc """
  Executes a plan by applying all approved changes to their respective works.

  Returns {:ok, plan} if all changes were applied successfully.
  Returns {:error, reason} if execution failed.

  ## Examples

      iex> execute_plan(plan)
      {:ok, %Plan{status: :executed}}

      iex> execute_plan(plan_with_no_approved_changes)
      {:error, "No approved changes to execute"}
  """
  def execute_plan(%Plan{status: :approved} = plan) do
    approved_changes = load_approved_changes(plan)

    approved_changes
    |> validate_has_changes()
    |> execute_changes_transaction(plan)
    |> handle_execution_result(plan)
  end

  def execute_plan(%Plan{}) do
    {:error, "Plan must be approved before execution"}
  end

  defp load_approved_changes(plan) do
    from(c in PlanChange,
      where: c.plan_id == ^plan.id and c.status == :approved,
      order_by: [asc: :inserted_at]
    )
    |> Repo.all()
  end

  defp validate_has_changes([]), do: {:error, "No approved changes to execute"}
  defp validate_has_changes(changes), do: {:ok, changes}

  defp execute_changes_transaction({:error, _} = error, _plan), do: error

  defp execute_changes_transaction({:ok, approved_changes}, plan) do
    Repo.transaction(
      fn ->
        Enum.each(approved_changes, &execute_single_change/1)

        mark_plan_executed(plan)
        |> unwrap_or_rollback()
      end,
      timeout: :infinity
    )
  end

  defp execute_single_change(change) do
    apply_change_to_work(change)
    |> handle_change_result(change)
  end

  defp handle_change_result({:ok, _work}, change) do
    mark_plan_change_executed(change)
    |> unwrap_or_rollback()
  end

  defp handle_change_result({:error, reason}, _change) do
    Repo.rollback(reason)
  end

  defp unwrap_or_rollback({:ok, result}), do: result
  defp unwrap_or_rollback({:error, reason}), do: Repo.rollback(reason)

  defp handle_execution_result({:ok, executed_plan}, _plan), do: {:ok, executed_plan}

  defp handle_execution_result({:error, "No approved changes to execute"} = error, _plan) do
    error
  end

  defp handle_execution_result({:error, reason}, plan) do
    mark_plan_error(plan, inspect(reason))
  end

  @doc """
  Executes a single plan change by applying the changeset to the work.

  ## Examples

      iex> execute_plan_change(change)
      {:ok, %PlanChange{status: :executed}}
  """
  def execute_plan_change(%PlanChange{} = change) do
    case apply_change_to_work(change) do
      {:ok, _work} ->
        mark_plan_change_executed(change)

      {:error, reason} ->
        mark_plan_change_error(change, inspect(reason))
    end
  end

  # Private plan creation helpers

  defp populate_plan_changes(plan, query) do
    try do
      query
      |> normalize_query()
      |> fetch_work_ids_from_query()
      |> create_plan_changes_for_works(plan.id)
    rescue
      e ->
        # Log the error but don't fail plan creation
        require Logger
        Logger.warning("Failed to auto-populate plan changes: #{Exception.message(e)}")
        :ok
    end

    plan
  end

  defp normalize_query(query) do
    # Try to decode as JSON first
    case Jason.decode(query) do
      {:ok, _} ->
        # Already valid JSON
        query

      {:error, _} ->
        # Simple query string - convert to OpenSearch query_string query
        %{
          "query" => %{
            "query_string" => %{
              "query" => query
            }
          }
        }
        |> Jason.encode!()
    end
  end

  defp fetch_work_ids_from_query(query) do
    alias Meadow.Search.Config, as: SearchConfig
    alias Meadow.Search.HTTP

    # The query should be a JSON string (like in Batches)
    # Convert it to a map, ensure _source is empty, then back to JSON
    query_body =
      query
      |> Jason.decode!()
      |> Map.put("_source", "")
      |> Jason.encode!()

    HTTP.post!([SearchConfig.alias_for(Work, 2), "_search?scroll=10m"], query_body)
    |> Map.get(:body)
    |> collect_work_ids([])
  end

  defp collect_work_ids(%{"hits" => %{"hits" => []}}, acc), do: acc

  defp collect_work_ids(%{"_scroll_id" => scroll_id, "hits" => hits}, acc) do
    alias Meadow.Search.HTTP

    work_ids =
      hits
      |> Map.get("hits")
      |> Enum.map(&Map.get(&1, "_id"))

    HTTP.post!("/_search/scroll", %{scroll: "1m", scroll_id: scroll_id})
    |> Map.get(:body)
    |> collect_work_ids(acc ++ work_ids)
  end

  defp create_plan_changes_for_works([], plan_id) do
    require Logger
    Logger.debug("No works found in OpenSearch results for plan #{plan_id}")
    :ok
  end

  defp create_plan_changes_for_works(work_ids, plan_id) do
    require Logger
    Logger.debug("Found #{length(work_ids)} works in OpenSearch results for plan #{plan_id}")

    # Validate work IDs exist in database
    valid_work_ids =
      from(w in Work, where: w.id in ^work_ids, select: w.id)
      |> Repo.all()

    Logger.debug("Validated #{length(valid_work_ids)} work IDs exist in database")

    # Create PlanChange records with empty changesets
    entries =
      Enum.map(valid_work_ids, fn work_id ->
        Logger.debug("Creating PlanChange for work #{work_id} in plan #{plan_id}")

        %{
          plan_id: plan_id,
          work_id: work_id,
          changeset: %{},
          status: :pending,
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        }
      end)

    {count, _} = Repo.insert_all(PlanChange, entries)
    Logger.debug("Created #{count} PlanChanges for plan #{plan_id}")
  end

  # Private execution helpers

  defp apply_change_to_work(%PlanChange{work_id: work_id, changeset: changeset_attrs}) do
    case Repo.get(Work, work_id) do
      nil ->
        {:error, "Work not found"}

      work ->
        work
        |> Work.update_changeset(changeset_attrs)
        |> Repo.update()
    end
  end
end
