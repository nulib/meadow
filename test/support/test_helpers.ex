defmodule Meadow.TestHelpers do
  @moduledoc """
  Meadow test helpers, fixtures, etc

  """
  alias Meadow.Accounts.Users.User
  alias Meadow.Ingest.IngestJobs.IngestJob
  alias Meadow.Ingest.Projects.Project
  alias Meadow.Repo

  def user_fixture(attrs \\ %{}) do
    username = "name-#{System.unique_integer([:positive])}"
    display_name = "Name #{System.unique_integer([:positive])}"
    email = "example-#{System.unique_integer([:positive])}@example.com"

    attrs =
      Enum.into(attrs, %{
        username: attrs[:username] || username,
        display_name: attrs[:display_name] || display_name,
        email: attrs[:email] || email
      })

    {:ok, user} =
      %User{}
      |> User.changeset(attrs)
      |> Repo.insert()

    user
  end

  def ingest_job_fixture(attrs \\ %{}) do
    project = project_fixture()
    name = "name-#{System.unique_integer([:positive])}"
    filename = "file-#{System.unique_integer([:positive])}.csv"

    attrs =
      Enum.into(attrs, %{
        name: attrs[:name] || name,
        filename: attrs[:filename] || filename,
        project_id: attrs[:project_id] || project.id
      })

    {:ok, ingest_job} =
      %IngestJob{}
      |> IngestJob.changeset(attrs)
      |> Repo.insert()

    ingest_job
  end

  def project_fixture(attrs \\ %{}) do
    title = "title-#{System.unique_integer([:positive])}"

    attrs =
      Enum.into(attrs, %{
        title: attrs[:title] || title
      })

    {:ok, project} =
      %Project{}
      |> Project.changeset(attrs)
      |> Repo.insert()

    project
  end

  def projects_fixture do
    project1 =
      %Project{
        title: "Project 1",
        id: "01DJ8TY8X1DYDP91Q6WJ4BNG0G"
      }
      |> Repo.insert!()

    project2 =
      %Project{
        title: "Project 2",
        id: "01DJ8V5VMY13F5EX9KA1SJGGBN"
      }
      |> Repo.insert!()

    project3 =
      %Project{
        title: "Project 3",
        id: "01DJ8V6TTJC85GBZ80V6ZNH9EY"
      }
      |> Repo.insert!()

    [project1, project2, project3]
  end
end
