defmodule Meadow.TestHelpers do
  @moduledoc """
  Meadow test helpers, fixtures, etc

  """
  alias Meadow.Accounts.Users.User
  alias Meadow.Data.{FileSet, Work}
  alias Meadow.Data.FileSets.FileSet
  alias Meadow.Data.Works.Work
  alias Meadow.Ingest.IngestSheets.IngestSheet
  alias Meadow.Ingest.Projects.Project

  alias Meadow.Repo

  use Meadow.Constants

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

  def ingest_sheet_fixture(attrs \\ %{}) do
    project = project_fixture()
    name = "name-#{System.unique_integer([:positive])}"
    filename = "file-#{System.unique_integer([:positive])}.csv"

    attrs =
      Enum.into(attrs, %{
        name: attrs[:name] || name,
        filename: attrs[:filename] || filename,
        project_id: attrs[:project_id] || project.id
      })

    {:ok, ingest_sheet} =
      %IngestSheet{}
      |> IngestSheet.changeset(attrs)
      |> Repo.insert()

    ingest_sheet
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

  def work_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        accession_number: attrs[:accession_number] || Faker.String.base64(),
        visibility: attrs[:visibility] || Faker.Util.pick(@visibility),
        work_type: attrs[:work_type] || Faker.Util.pick(@work_types),
        metadata:
          attrs[:metadata] ||
            %{
              title: "Test title"
            },
        file_sets: attrs[:file_sets] || []
      })

    {:ok, work} =
      %Work{}
      |> Work.changeset(attrs)
      |> Repo.insert()

    work
  end

  def file_set_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        accession_number: attrs[:accession_number] || Faker.String.base64(),
        metadata:
          attrs[:metadata] ||
            %{
              location: "https://fake-s3-bucket/" <> Faker.String.base64(),
              original_filename: Faker.File.file_name()
            }
      })

    {:ok, work} =
      %FileSet{}
      |> FileSet.changeset(attrs)
      |> Repo.insert()

    work
  end
end
