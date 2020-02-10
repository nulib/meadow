defmodule Meadow.Ingest.Projects do
  @moduledoc """
  Secondary Context for projects
  """

  import Ecto.Query, warn: false

  alias Meadow.Ingest.Schemas.Project
  alias Meadow.Repo

  @doc """
  Returns the list of projects in reverse chronological order.
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
        from p in query, order_by: [{^order, :updated_at}, {^order, :title}]
    end)
    |> Repo.all()
  end

  @doc """
  Gets a single project by id (generates project folder).

  Raises `Ecto.NoResultsError` if the Project does not exist.
  """
  def get_project!(id), do: Repo.get!(Project, id)

  @doc """
  Creates a project.
  """
  def create_project(attrs \\ %{}) do
    %Project{}
    |> Project.changeset(:create, attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a project. (does not generate project folder)
  """
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(:update, attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Project.
  """
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sheet changes.
  """
  def change_project(%Project{} = sheet) do
    Project.changeset(sheet, %{})
  end
end
