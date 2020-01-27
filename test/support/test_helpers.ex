defmodule Meadow.TestHelpers do
  @moduledoc """
  Meadow test helpers, fixtures, etc

  """
  alias Ecto.Adapters.SQL.Sandbox

  alias Meadow.Accounts.User
  alias Meadow.Data.{Collection, FileSet, Work}
  alias Meadow.Data.Schemas.Collection
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Data.Schemas.Work
  alias Meadow.Ingest.Validator
  alias Meadow.Ingest.Schemas.{Project, Sheet}

  alias Meadow.Repo

  use Meadow.Constants

  import Meadow.LdapHelpers

  def user_fixture do
    username = "name-#{System.unique_integer([:positive])}"

    with {:ok, connection} <- Exldap.connect() do
      user_dn = "CN=#{username},OU=NotMeadow,DC=library,DC=northwestern,DC=edu" |> to_charlist()
      add_entry(connection, user_dn, people_attributes(username))
      add_membership(connection, "CN=Users,OU=Meadow,DC=library,DC=northwestern,DC=edu", user_dn)
      user_dn
    end

    User.find(username)
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
      %Sheet{}
      |> Sheet.changeset(attrs)
      |> Repo.insert()

    ingest_sheet
  end

  def ingest_sheet_rows_fixture(file_fixture) do
    sheet = ingest_sheet_fixture()

    sheet
    |> Repo.preload(:project)
    |> Validator.load_rows(File.read!(file_fixture))

    sheet
  end

  def project_fixture(attrs \\ %{}) do
    title = "title-#{System.unique_integer([:positive])}"

    attrs =
      Enum.into(attrs, %{
        title: attrs[:title] || title
      })

    {:ok, project} =
      %Project{}
      |> Project.changeset(:create, attrs)
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

  def collection_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: attrs[:name] || "collection-#{System.unique_integer([:positive])}",
        description: attrs[:description] || "Description of collection",
        keywords: attrs[:keywords] || ["keyword1", "keyword 2", "keyword 3"]
      })

    {:ok, collection} =
      %Collection{}
      |> Collection.changeset(attrs)
      |> Repo.insert()

    collection
  end

  def work_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        accession_number: attrs[:accession_number] || Faker.String.base64(),
        visibility: attrs[:visibility] || Faker.Util.pick(@visibility),
        work_type: attrs[:work_type] || Faker.Util.pick(@work_types),
        descriptive_metadata:
          attrs[:descriptive_metadata] ||
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
        role: attrs[:role] || Faker.Util.pick(@file_set_roles),
        metadata:
          attrs[:metadata] ||
            %{
              description: attrs[:description] || Faker.String.base64(),
              location: "https://fake-s3-bucket/" <> Faker.String.base64(),
              original_filename: Faker.File.file_name()
            }
      })

    {:ok, file_set} =
      %FileSet{}
      |> FileSet.changeset(attrs)
      |> Repo.insert()

    file_set
  end

  def gql_context(extra \\ %{}) do
    extra
    |> Map.merge(%{
      current_user: %{
        username: "user1",
        email: "email@example.com",
        display_name: "User Name"
      }
    })
  end

  def sandbox_mode(tags) do
    result =
      case Sandbox.checkout(Meadow.Repo) do
        :ok -> :ok
        {:already, :owner} -> :ok
        other -> other
      end

    unless tags[:async] do
      Sandbox.mode(Meadow.Repo, {:shared, self()})
    end

    result
  end
end
