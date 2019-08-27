defmodule Meadow.Ingest do
  @moduledoc """
  The Ingest context.
  """

  import Ecto.Query, warn: false
  alias Meadow.Ingest.{IngestJob, IngestRow, Project}
  alias Meadow.Repo
  alias Meadow.Utils.MapList

  @doc """
  Returns the list of projects in reverse chronological order.

  ## Examples

      iex> list_projects()
      [%Project{}, ...]

  """
  def list_projects do
    Repo.all(Project)
  end

  @doc """
  Returns a list of projects matching the given `criteria`.

  Example Criteria:

  [{:limit, 15}, {:order, :asc}]
  """
  def list_projects(criteria) do
    query = from(p in Project)

    Enum.reduce(criteria, query, fn
      {:limit, limit}, query ->
        from p in query, limit: ^limit

      {:order, order}, query ->
        from p in query, order_by: [{^order, :id}]
    end)
    |> Repo.all()
  end

  @doc """
  Gets a single project.

  Raises `Ecto.NoResultsError` if the Project does not exist.

  ## Examples

      iex> get_project!(123)
      %Project{}

      iex> get_project!(456)
      ** (Ecto.NoResultsError)

  """
  def get_project!(id), do: Repo.get!(Project, id)

  @doc """
  Creates a project.

  ## Examples

      iex> create_project(%{field: value})
      {:ok, %Project{}}

      iex> create_project(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_project(attrs \\ %{}) do
    %Project{}
    |> Project.changeset(:create, attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a project.

  ## Examples

      iex> update_project(project, %{field: new_value})
      {:ok, %Project{}}

      iex> update_project(project, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(:update, attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Project.

  ## Examples

      iex> delete_project(project)
      {:ok, %Project{}}

      iex> delete_project(project)
      {:error, %Ecto.Changeset{}}

  """
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project changes.

  ## Examples

      iex> change_project(project)
      %Ecto.Changeset{source: %Project{}}

  """
  def change_project(%Project{} = project) do
    Project.changeset(project, %{})
  end

  @doc """
  Returns the list of ingest_jobs in a project.

  ## Examples

      iex> list_ingest_jobs()
      [%Job{}, ...]

  """
  def list_ingest_jobs(project) do
    IngestJob
    |> where([ingest_job], ingest_job.project_id == ^project.id)
    |> Repo.all()
  end

  @doc """
  Returns the list of all ingest_jobs in all projects.
  ## Examples
      iex> list_all_ingest_jobs()
      [%Job{}, ...]
  """
  def list_all_ingest_jobs do
    IngestJob
    |> Repo.all()
  end

  @doc """
  Gets a single job.

  Raises `Ecto.NoResultsError` if the Job does not exist.

  ## Examples

      iex> get_job!(123)
      %Job{}

      iex> get_job!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ingest_job!(id) do
    IngestJob
    |> Repo.get!(id)
  end

  @doc """
  Gets the list of states for a single job.

  ## Examples

      iex> get_job_state(123)
      [
        %{ name: "overall", value: "pending" }
      ]
  """
  def get_job_state(id) do
    IngestJob
    |> select([job], job.state)
    |> where([job], job.id == ^id)
    |> Repo.one()
  end

  @doc """
  Creates a job.

  ## Examples

      iex> create_ingest_row(%{field: value})
      {:ok, %Job{}}

      iex> create_ingest_row(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ingest_job(attrs \\ %{}) do
    %IngestJob{}
    |> IngestJob.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Changes the state of an IngestJob Event
  """
  def change_ingest_job_state(%IngestJob{} = ingest_job, updates) do
    new_state =
      get_job_state(ingest_job.id)
      |> MapList.merge(:name, :state, updates)
      |> Enum.map(fn
        %IngestJob.State{} = m -> Map.from_struct(m)
        other -> other
      end)

    ingest_job
    |> IngestJob.changeset(%{state: new_state})
    |> Repo.update()
    |> send_ingest_job_notification()
  end

  def change_ingest_job_state!(%IngestJob{} = ingest_job, updates) do
    case change_ingest_job_state(ingest_job, updates) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc """
  Updates a job.

  ## Examples
      iex> update_job(job, %{field: new_value})
      {:ok, %Job{}}

      iex> update_job(job, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ingest_job(%IngestJob{} = ingest_job, attrs) do
    ingest_job
    |> IngestJob.changeset(attrs)
    |> Repo.update()
    |> send_ingest_job_notification()
  end

  @doc """
  Deletes a Job.

  ## Examples

      iex> delete_job(job)
      {:ok, %Job{}}

      iex> delete_job(job)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ingest_job(%IngestJob{} = ingest_job) do
    Repo.delete(ingest_job)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking job changes.

  ## Examples

      iex> change_job(job)
      %Ecto.Changeset{source: %Job{}}

  """
  def change_ingest_job(%IngestJob{} = job) do
    IngestJob.changeset(job, %{})
  end

  @doc """
  Returns row counts for one or more IngestJobs grouped by state
  """
  def list_ingest_job_row_counts(ids) when is_list(ids) do
    aggregate = fn rows ->
      rows |> Enum.map(fn [_job_id, state, count] -> %{state: state, count: count} end)
    end

    ids = ids |> Enum.uniq()

    IngestRow
    |> select([row], [row.ingest_job_id, row.state, count(row)])
    |> where([row], row.ingest_job_id in ^ids)
    |> group_by([row], [row.ingest_job_id, row.state])
    |> order_by([row], asc: row.ingest_job_id, asc: row.state)
    |> Meadow.Repo.all()
    |> Enum.chunk_by(fn [job_id, _, _] -> [job_id] end)
    |> Enum.map(fn rows ->
      {
        rows |> List.first() |> List.first(),
        aggregate.(rows)
      }
    end)
    |> Enum.into(%{})
  end

  def list_ingest_job_row_counts(job_id) when is_binary(job_id) do
    case Map.get(list_ingest_job_row_counts([job_id]), job_id) do
      nil -> []
      other -> other
    end
  end

  def list_ingest_job_row_counts(%IngestJob{} = job) do
    list_ingest_job_row_counts(job.id)
  end

  @doc """
  Returns the list of ingest_rows matching a set of criteria.

  ## Examples

      iex> list_ingest_rows(ingest_job: %Job{})
      [%IngestRow{}, ...]

      iex> list_ingest_rows(ingest_job: %Job{}, state: ["error"])
      [%IngestRow{}, ...]
  """
  def list_ingest_rows(criteria) do
    criteria
    |> Enum.reduce(IngestRow, fn
      {:job, job}, query ->
        from(r in query) |> where([ingest_row], ingest_row.ingest_job_id == ^job.id)

      {:job_id, job_id}, query ->
        from(r in query) |> where([ingest_row], ingest_row.ingest_job_id == ^job_id)

      {:state, state}, query ->
        from(r in query) |> where([ingest_row], ingest_row.state in ^state)

      {:start, start}, query ->
        from(r in query) |> where([ingest_row], ingest_row.row >= ^start)

      {:limit, limit}, query ->
        from r in query, limit: ^limit

      _, query ->
        query
    end)
    |> order_by(asc: :row)
    |> Repo.all()
  end

  @doc """
  Changes the state of an IngestRow
  """
  def change_ingest_row_state(%IngestRow{} = ingest_row, state) do
    ingest_row
    |> IngestRow.state_changeset(%{state: state})
    |> Repo.update()
    |> send_ingest_row_notification()
  end

  @doc """
  Updates an ingest row.

  ## Examples
      iex> update_ingest_row(row, %{field: new_value})
      {:ok, %IngestRow{}}

      iex> update_ingest_row(row, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ingest_row(%IngestRow{} = ingest_row, attrs) do
    ingest_row
    |> IngestRow.changeset(attrs)
    |> Repo.update()
    |> send_ingest_row_notification()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking job changes.

  ## Examples

      iex> change_ingest_row(row)
      %Ecto.Changeset{source: %Row{}}

  """
  def change_ingest_row(%IngestRow{} = row) do
    IngestRow.changeset(row, %{})
  end

  # Absinthe Notifications

  defp send_ingest_job_notification({:ok, job}), do: {:ok, send_ingest_job_notification(job)}

  defp send_ingest_job_notification(%IngestJob{} = job) do
    Absinthe.Subscription.publish(
      MeadowWeb.Endpoint,
      job,
      ingest_job_update: "job:" <> job.id
    )

    job
  end

  defp send_ingest_job_notification(other), do: other

  defp send_ingest_row_notification({:ok, row}), do: {:ok, send_ingest_row_notification(row)}

  defp send_ingest_row_notification(%IngestRow{} = row) do
    Absinthe.Subscription.publish(
      MeadowWeb.Endpoint,
      row,
      ingest_job_row_update: "row:" <> row.ingest_job_id
    )

    row
  end

  defp send_ingest_row_notification(other), do: other

  # Dataloader

  def datasource do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(queryable, _) do
    queryable
  end
end
