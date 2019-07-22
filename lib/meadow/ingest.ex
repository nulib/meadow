defmodule Meadow.Ingest do
  @moduledoc """
  The Ingest context.
  """

  import Ecto.Query, warn: false
  alias Meadow.Ingest.IngestJob
  alias Meadow.Ingest.Project
  alias Meadow.Repo

  @doc """
  Returns the list of projects in reverse chronological order.

  ## Examples

      iex> list_projects()
      [%Project{}, ...]

  """
  def list_projects do
    Project
    |> order_by(desc: :updated_at)
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
  def get_ingest_job!(project, id) do
    IngestJob
    |> where([ingest_job], ingest_job.project_id == ^project.id)
    |> Repo.get!(id)
  end

  @doc """
  Creates a job.

  ## Examples

      iex> create_job(%{field: value})
      {:ok, %Job{}}

      iex> create_job(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ingest_job(attrs \\ %{}) do
    %IngestJob{}
    |> IngestJob.changeset(attrs)
    |> Repo.insert()
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
end
