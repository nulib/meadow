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
         add: %{
           descriptive_metadata: %{
             subject: [
               %{
                 role: %{id: "TOPICAL", scheme: "subject_role"},
                 term: %{id: "http://id.loc.gov/authorities/subjects/sh85141086"}
               }
             ]
           }
         }
       }) do
         {:ok, _updated_change} -> :ok
         {:error, message} -> Logger.error("Error: " <> message)
       end
     end)
     ```

  3. **Review**: User reviews and approves/rejects plan and individual changes
     ```
     approve_plan(plan, "user-netid")
     approve_plan_change(change, "user-netid")
     ```

  4. **Apply**: Apply approved changes to works
     ```
     apply_plan(plan)
     ```
  """
  import Ecto.Query, warn: false
  alias Meadow.Data.Schemas.{Plan, PlanChange}
  alias Meadow.Data.Schemas.Work
  alias Meadow.Data.Works
  alias Meadow.Repo
  alias Meadow.Utils.{Atoms, ChangesetErrors, StructMap}

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

      [{:limit, 15}, {:status, :proposed}, {:user, "user-netid"}]

  ## Examples

      iex> list_plans([status: :proposed])
      [%Plan{status: :proposed}, ...]
  """
  def list_plans(criteria) do
    criteria
    |> plan_query()
    |> Repo.all()
  end

  @doc """
  Returns a composable query matching the given criteria.

  ## Examples

      iex> plan_query([status: :proposed]) |> Repo.all()
      [%Plan{status: :proposed}, ...]
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
    get_plan_query(id, opts)
    |> Repo.one!()
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
    get_plan_query(id, opts)
    |> Repo.one()
  end

  @doc """
  Returns a query for getting a plan with optional preloading of changes.

  ## Examples
      iex> get_plan_query("123", preload_changes: true)
      iex> get_plan_query("123", preload_changes: :empty)
      iex> get_plan_query("123", preload_changes: :not_empty)
  """
  def get_plan_query(id, opts) do
    from(p in Plan, where: p.id == ^id)
    |> preload_plan_changes(opts[:preload_changes])
  end

  @doc """
  Gets proposed plans.

  ## Examples

      iex> get_proposed_plans()
      [%Plan{status: :proposed}, ...]
  """
  def get_proposed_plans(opts \\ []) do
    query = from(p in Plan, where: p.status == :proposed, order_by: [asc: :inserted_at])

    query =
      if opts[:preload_changes] do
        from(p in query, preload: :plan_changes)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets approved plans ready to apply.

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
      {:ok, plan} ->
        plan

      {:error, changeset} ->
        raise Ecto.InvalidChangesetError, action: :insert, changeset: changeset
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
  Approves a plan and optionally all its proposed changes.

  ## Examples

      iex> approve_plan(plan, "user-netid")
      {:ok, %Plan{status: :approved, user: "user-netid"}}

      iex> approve_plan(plan, "user-netid", approve_changes: true)
      {:ok, %Plan{status: :approved, user: "user-netid"}}
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
  Marks a plan as completed.

  ## Examples

      iex> mark_plan_completed(plan)
      {:ok, %Plan{status: :completed}}
  """
  def mark_plan_completed(%Plan{} = plan) do
    plan
    |> Plan.mark_completed()
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

      [{:status, :proposed}, {:work_id, "work-123"}]

  ## Examples

      iex> list_plan_changes(plan_id, [status: :proposed])
      [%PlanChange{status: :proposed}, ...]

      iex> list_plan_changes(plan, [status: :proposed])
      [%PlanChange{status: :proposed}, ...]
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

  def get_plan_changes_by_work(%Plan{id: plan_id}, work_id),
    do: get_plan_changes_by_work(plan_id, work_id)

  def get_plan_changes_by_work(plan_id, %Work{id: work_id}),
    do: get_plan_changes_by_work(plan_id, work_id)

  def get_plan_changes_by_work(plan_id, work_id)
      when is_binary(plan_id) and is_binary(work_id) do
    from(c in PlanChange, where: c.plan_id == ^plan_id and c.work_id == ^work_id)
    |> Repo.all()
  end

  @doc """
  Creates a plan change.

  ## Examples

      iex> create_plan_change(%{
      ...>   plan_id: plan.id,
      ...>   work_id: "work-123",
      ...>   add: %{
      ...>     descriptive_metadata: %{
      ...>       subject: [
      ...>         %{
      ...>           role: %{id: "TOPICAL", scheme: "subject_role"},
      ...>           term: %{id: "http://id.loc.gov/authorities/subjects/sh85141086"}
      ...>         }
      ...>       ]
      ...>     }
      ...>   }
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
      ...>   %{
      ...>     plan_id: plan.id,
      ...>     work_id: "work-1",
      ...>     add: %{
      ...>       descriptive_metadata: %{
      ...>         subject: [%{role: %{id: "TOPICAL", scheme: "subject_role"}, term: %{id: "http://..."}}]
      ...>       }
      ...>     }
      ...>   },
      ...>   %{
      ...>     plan_id: plan.id,
      ...>     work_id: "work-2",
      ...>     add: %{
      ...>       descriptive_metadata: %{
      ...>         subject: [%{role: %{id: "TOPICAL", scheme: "subject_role"}, term: %{id: "http://..."}}]
      ...>       }
      ...>     }
      ...>   }
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

      iex> approve_plan_change(change, "user-netid")
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
  Marks a plan change as completed.

  ## Examples

      iex> mark_plan_change_completed(change)
      {:ok, %PlanChange{status: :completed}}
  """
  def mark_plan_change_completed(%PlanChange{} = change) do
    change
    |> PlanChange.mark_completed()
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
  Applies a plan by applying all approved changes to their respective works.

  Returns {:ok, plan} if all changes were completed successfully.
  Returns {:error, reason} if plan failed.

  ## Examples

      iex> apply_plan(plan)
      {:ok, %Plan{status: :completed}}

      iex> apply_plan(plan_with_no_approved_changes)
      {:error, "No approved changes to apply"}
  """
  def apply_plan(%Plan{status: :approved} = plan) do
    approved_changes = load_approved_changes(plan)

    approved_changes
    |> validate_has_changes()
    |> apply_changes_transaction(plan)
    |> handle_apply_changes_result(plan)
  end

  def apply_plan(%Plan{}) do
    {:error, "Plan must be approved before applying"}
  end

  defp load_approved_changes(plan) do
    from(c in PlanChange,
      where: c.plan_id == ^plan.id and c.status == :approved,
      order_by: [asc: :inserted_at]
    )
    |> Repo.all()
  end

  defp validate_has_changes([]), do: {:error, "No approved changes to apply"}
  defp validate_has_changes(changes), do: {:ok, changes}

  defp apply_changes_transaction({:error, _} = error, _plan), do: error

  defp apply_changes_transaction({:ok, approved_changes}, plan) do
    Repo.transaction(
      fn ->
        Enum.each(approved_changes, &apply_single_change/1)

        mark_plan_completed(plan)
        |> unwrap_or_rollback()
      end,
      timeout: :infinity
    )
  end

  defp apply_single_change(change) do
    apply_change_to_work(change)
    |> handle_change_result(change)
  end

  defp handle_change_result({:ok, _work}, change) do
    mark_plan_change_completed(change)
    |> unwrap_or_rollback()
  end

  defp handle_change_result({:error, reason}, _change) do
    Repo.rollback(reason)
  end

  defp unwrap_or_rollback({:ok, result}), do: result
  defp unwrap_or_rollback({:error, reason}), do: Repo.rollback(reason)

  defp handle_apply_changes_result({:ok, completed_plan}, _plan), do: {:ok, completed_plan}

  defp handle_apply_changes_result({:error, "No approved changes to apply"} = error, _plan) do
    error
  end

  defp handle_apply_changes_result({:error, reason}, plan) do
    mark_plan_error(plan, inspect(reason))
  end

  @doc """
  Applies a single plan change's changeset to the work.

  ## Examples

      iex> apply_plan_change(change)
      {:ok, %PlanChange{status: :completed}}
  """
  def apply_plan_change(%PlanChange{} = change) do
    case apply_change_to_work(change) do
      {:ok, _work} ->
        mark_plan_change_completed(change)

      {:error, reason} ->
        mark_plan_change_error(change, inspect(reason))
    end
  end

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
    alias Meadow.Search.Scroll

    # The query should be a JSON string (like in Batches)
    # Convert it to a map, ensure _source is empty, then back to JSON
    query_body =
      query
      |> Jason.decode!()
      |> Map.put("_source", "")
      |> Jason.encode!()

    Scroll.results(query_body, SearchConfig.alias_for(Work, 2))
    |> Stream.map(&Map.get(&1, "_id"))
    |> Enum.to_list()
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

    # Create PlanChange records with empty add/delete/replace maps
    entries =
      Enum.map(valid_work_ids, fn work_id ->
        Logger.debug("Creating PlanChange for work #{work_id} in plan #{plan_id}")

        %{
          plan_id: plan_id,
          work_id: work_id,
          add: %{},
          status: :proposed,
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        }
      end)

    {count, _} = Repo.insert_all(PlanChange, entries)
    Logger.debug("Created #{count} PlanChanges for plan #{plan_id}")
  end

  defp apply_change_to_work(%PlanChange{work_id: work_id} = plan_change) do
    case Repo.get(Work, work_id) do
      nil ->
        {:error, "Work not found"}

      work ->
        apply_operations_to_work(work, plan_change)
    end
  end

  defp apply_operations_to_work(work, %PlanChange{delete: delete, add: add, replace: replace}) do
    delete = if is_nil(delete), do: %{}, else: delete
    add = if is_nil(add), do: %{}, else: add
    replace = if is_nil(replace), do: %{}, else: replace

    Repo.transaction(fn ->
      # Apply controlled field changes (delete/add operations)
      apply_controlled_field_operations(work, delete, add)

      # Apply uncontrolled field changes (add/replace operations)
      apply_uncontrolled_field_operations(work, add, replace)

      # Reload the work to get the updated state
      Repo.get!(Work, work.id)
    end)
  end

  @controlled_fields ~w(contributor creator genre language location style_period subject technique)a

  defp apply_controlled_field_operations(work, delete, add) do
    @controlled_fields
    |> Enum.each(fn field ->
      delete_values = controlled_field_values(delete, field)
      add_values = controlled_field_values(add, field)

      unless is_nil(delete_values) and is_nil(add_values) do
        apply_controlled_field_operation(
          work.id,
          field,
          prepare_controlled_field_list(delete_values),
          prepare_controlled_field_list(add_values)
        )
      end
    end)
  end

  defp apply_controlled_field_operation(work_id, field, delete_values, add_values) do
    require Logger
    Logger.debug("Applying controlled field operation for #{field}")

    from(w in Work, where: w.id == ^work_id)
    |> Works.replace_controlled_value(
      :descriptive_metadata,
      to_string(field),
      delete_values,
      add_values
    )
    |> Repo.update_all([])
  end

  defp prepare_controlled_field_list(nil), do: []
  defp prepare_controlled_field_list([]), do: []

  defp prepare_controlled_field_list(data) when is_list(data) do
    Enum.map(data, &normalize_controlled_field_entry/1)
  end

  defp prepare_controlled_field_list(data), do: prepare_controlled_field_list([data])

  defp controlled_field_values(data, field) when is_map(data) do
    metadata = Map.get(data, :descriptive_metadata) || Map.get(data, "descriptive_metadata")

    case metadata do
      nil -> nil
      %{} = meta -> Map.get(meta, field) || Map.get(meta, Atom.to_string(field))
    end
  end

  defp controlled_field_values(_data, _field), do: nil

  defp normalize_controlled_field_entry(entry) do
    entry
    |> StructMap.deep_struct_to_map()
    |> Atoms.atomize()
    |> Map.put_new(:role, nil)
    |> normalize_role()
    |> normalize_term()
  end

  defp normalize_role(%{role: nil} = entry), do: entry

  defp normalize_role(%{role: role} = entry) when is_map(role) do
    normalized_role =
      role
      |> StructMap.deep_struct_to_map()
      |> Map.take([:id, :scheme])
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Enum.into(%{})

    Map.put(entry, :role, if(map_size(normalized_role) == 0, do: nil, else: normalized_role))
  end

  defp normalize_role(entry), do: Map.put(entry, :role, nil)

  defp normalize_term(%{term: %{} = term} = entry) do
    normalized_term =
      term
      |> StructMap.deep_struct_to_map()
      |> Map.take([:id])

    Map.put(entry, :term, if(map_size(normalized_term) == 0, do: nil, else: normalized_term))
  end

  defp normalize_term(entry), do: entry

  defp apply_uncontrolled_field_operations(work, add, replace) do
    # Extract collection_id and top-level fields from replace
    collection_id = Map.get(replace, :collection_id, :not_present)
    visibility = Map.get(replace, :visibility, :not_present)
    published = Map.get(replace, :published, :not_present)

    work.id
    |> update_top_level_field(:collection_id, collection_id)
    |> update_top_level_field(:visibility, visibility)
    |> update_top_level_field(:published, published)
    |> merge_uncontrolled_metadata(add, :append)
    |> merge_uncontrolled_metadata(replace, :replace)
  end

  defp update_top_level_field(work_id, _field, :not_present), do: work_id

  defp update_top_level_field(work_id, field, value) do
    require Logger
    Logger.debug("Updating #{field} to #{inspect(value)}")

    update_args = Keyword.new([{field, value}, {:updated_at, DateTime.utc_now()}])

    from(w in Work, where: w.id == ^work_id, update: [set: ^update_args])
    |> Repo.update_all([])

    work_id
  end

  defp merge_uncontrolled_metadata(work_id, new_values, _mode) when map_size(new_values) == 0 do
    work_id
  end

  defp merge_uncontrolled_metadata(work_id, new_values, mode) do
    descriptive_metadata =
      new_values
      |> metadata_section(:descriptive_metadata)
      |> Atoms.atomize()

    mergeable_descriptive_metadata =
      descriptive_metadata
      |> Enum.filter(fn {key, _} -> key not in @controlled_fields end)
      |> Enum.into(%{})
      |> humanize_date_created()

    mergeable_administrative_metadata =
      new_values
      |> metadata_section(:administrative_metadata)
      |> Atoms.atomize()
      |> Enum.into(%{})

    if map_size(mergeable_descriptive_metadata) + map_size(mergeable_administrative_metadata) > 0 do
      from(w in Work, where: w.id == ^work_id)
      |> Works.merge_metadata_values(
        :descriptive_metadata,
        mergeable_descriptive_metadata,
        mode
      )
      |> Works.merge_metadata_values(
        :administrative_metadata,
        mergeable_administrative_metadata,
        mode
      )
      |> Works.merge_updated_at()
      |> Repo.update_all([])
    end

    work_id
  end

  defp metadata_section(map, key) when is_map(map) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key)) || %{}
  end

  defp metadata_section(_map, _key), do: %{}

  defp humanize_date_created(descriptive_metadata) do
    case Map.fetch(descriptive_metadata, :date_created) do
      {:ok, date_created} ->
        put_humanized_dates(descriptive_metadata, :date_created, date_created)

      :error ->
        case Map.fetch(descriptive_metadata, "date_created") do
          {:ok, date_created} ->
            put_humanized_dates(descriptive_metadata, "date_created", date_created)

          :error ->
            descriptive_metadata
        end
    end
  end

  defp put_humanized_dates(descriptive_metadata, key, date_created) do
    dates =
      date_created
      |> Enum.map(&coerce_date_entry/1)
      |> Enum.reject(&is_nil/1)

    Map.put(descriptive_metadata, key, dates)
  end

  defp humanize_edtf(nil), do: nil

  defp humanize_edtf(edtf) when is_binary(edtf) do
    case EDTF.humanize(edtf) do
      {:error, error} -> raise error
      result -> %{edtf: edtf, humanized: result}
    end
  end

  defp coerce_date_entry(entry) when is_binary(entry), do: humanize_edtf(entry)

  defp coerce_date_entry(entry) when is_map(entry) do
    entry
    |> Map.new(fn {key, value} -> {Atoms.atomize(key), value} end)
    |> normalize_date_entry()
  end

  defp coerce_date_entry(_entry), do: humanize_edtf(nil)

  defp normalize_date_entry(%{edtf: nil}), do: humanize_edtf(nil)

  defp normalize_date_entry(%{edtf: edtf, humanized: humanized})
       when not is_nil(edtf) and not is_nil(humanized) do
    %{edtf: edtf, humanized: humanized}
  end

  defp normalize_date_entry(%{edtf: edtf}) when not is_nil(edtf), do: humanize_edtf(edtf)

  defp normalize_date_entry(_entry), do: humanize_edtf(nil)

  defp preload_plan_changes(query, true), do: preload(query, :plan_changes)

  defp preload_plan_changes(query, filter) when filter in [:empty, :not_empty] do
    subquery = from(c in PlanChange, where: ^change_fragment(filter), select: c)
    preload(query, plan_changes: ^subquery)
  end

  defp preload_plan_changes(query, _), do: query

  defp change_fragment(:empty) do
    dynamic(
      [c],
      fragment(
        """
          (?.add IS NULL OR ?.add = jsonb_build_object())
          AND (?.delete IS NULL OR ?.delete = jsonb_build_object())
          AND (?.replace IS NULL OR ?.replace = jsonb_build_object())
        """,
        c,
        c,
        c,
        c,
        c,
        c
      )
    )
  end

  defp change_fragment(:not_empty) do
    dynamic(
      [c],
      fragment(
        """
          (?.add IS NOT NULL AND ?.add != jsonb_build_object())
          OR (?.delete IS NOT NULL AND ?.delete != jsonb_build_object())
          OR (?.replace IS NOT NULL AND ?.replace != jsonb_build_object())
        """,
        c,
        c,
        c,
        c,
        c,
        c
      )
    )
  end
end
