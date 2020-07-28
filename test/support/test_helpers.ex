defmodule Meadow.TestHelpers do
  @moduledoc """
  Meadow test helpers, fixtures, etc

  """
  alias Ecto.Adapters.SQL.Sandbox

  alias Meadow.Accounts.{Ldap, User}
  alias Meadow.Data.Schemas.{Collection, FileSet, Work}
  alias Meadow.Data.Works
  alias Meadow.Ingest.Validator
  alias Meadow.Ingest.Schemas.{Project, Sheet}

  alias Meadow.Repo

  alias NimbleCSV.RFC4180, as: CSV

  use Meadow.Constants

  @test_users %{
    "TestAdmins" => ~w[auy5400 auk0124 auh7250 aud6389],
    "TestManagers" => ~w[aut2418 aum1701 auf2249 aua6615],
    :access => ~w[auy5400 auk0124 auh7250 aud6389 aut2418 aum1701 auf2249 aua6615],
    :noAccess => ~w[aup9261 aup6836 aui9865 auj5680 auq9679],
    :unknown => ~w[unknownUser]
  }

  def test_users(category \\ :access), do: @test_users |> Map.get(category)
  def random_user(category \\ :access), do: category |> test_users |> Enum.random()
  def user_fixture(category \\ :access), do: category |> random_user() |> User.find()

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
    |> Validator.load_rows(File.read!(file_fixture) |> uniqify_ingest_sheet_rows())

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
        id: "c5ea7b82-6afe-40ba-8229-5a9d21f0764b"
      }
      |> Repo.insert!()

    project2 =
      %Project{
        title: "Project 2",
        id: "50e195ed-47b9-4bdb-9796-835b8b4fa149"
      }
      |> Repo.insert!()

    project3 =
      %Project{
        title: "Project 3",
        id: "4f677f01-23d5-48f3-bbfd-3f209eae9581"
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
        visibility: attrs[:visibility] || %{id: "OPEN", scheme: "visibility"},
        work_type: attrs[:work_type] || %{id: "IMAGE", scheme: "work_type"},
        administrative_metadata:
          attrs[:administrative_metadata] ||
            %{
              project_name: [Faker.Lorem.sentence(3)],
              project_desc: [Faker.Lorem.sentence()],
              project_proposer: [Faker.Person.name()],
              project_manager: [Faker.Person.name()],
              project_task_number: [Faker.Code.issn()],
              project_cycle: Faker.Lorem.word()
            },
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

  def work_with_file_sets_fixture(count, work_attrs \\ %{}, file_set_attrs \\ %{}) do
    attrs =
      Enum.into(work_attrs, %{
        file_sets: 1..count |> Enum.map(fn _ -> file_set_fixture_attrs(file_set_attrs) end)
      })

    work_fixture(attrs) |> Works.set_default_representative_image!()
  end

  def file_set_fixture_attrs(attrs \\ %{}) do
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
  end

  def file_set_fixture(attrs \\ %{}) do
    attrs = file_set_fixture_attrs(attrs)

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

  def delete_entry(dn) do
    with {:ok, conn} <- Exldap.connect() do
      :eldap.delete(conn, to_charlist(dn))
    end
  end

  def entry_names([]), do: []
  def entry_names(%Ldap.Entry{} = entry), do: entry.name
  def entry_names([entry | entries]), do: [entry_names(entry) | entry_names(entries)]
  def meadow_dn(cn), do: "CN=#{cn},OU=Meadow,DC=library,DC=northwestern,DC=edu"
  def test_users_dn(cn), do: "CN=#{cn},OU=TestUsers,DC=library,DC=northwestern,DC=edu"

  defp uniqify_ingest_sheet_rows(csv) do
    with prefix <- test_id() do
      [headers | rows] = CSV.parse_string(csv, skip_headers: false)

      rows =
        rows
        |> Enum.map(fn [wan | [an | rest]] ->
          ["#{prefix}_#{wan}", "#{prefix}_#{an}"] ++ rest
        end)

      [headers | rows]
      |> CSV.dump_to_iodata()
      |> IO.iodata_to_binary()
    end
  end

  defp test_id do
    min = String.to_integer("100000", 36)
    max = String.to_integer("ZZZZZZ", 36)

    max
    |> Kernel.-(min)
    |> :rand.uniform()
    |> Kernel.+(min)
    |> Integer.to_string(36)
  end
end
