defmodule Meadow.TestHelpers do
  @moduledoc """
  Meadow test helpers, fixtures, etc

  """
  alias Meadow.Accounts.{Ldap, User}
  alias Meadow.Data.Schemas.{Batch, Collection, FileSet, Work}
  alias Meadow.Data.Works
  alias Meadow.Ingest.Validator
  alias Meadow.Ingest.Schemas.{Project, Sheet}
  alias Meadow.TestSupport.MetadataGenerator

  alias Meadow.Repo

  alias NimbleCSV.RFC4180, as: CSV

  @test_users %{
    "TestAdmins" => ~w[auy5400 auk0124 auh7250 aud6389],
    "TestManagers" => ~w[aut2418 aum1701 auf2249 aua6615],
    :access => ~w[auy5400 auk0124 auh7250 aud6389 aut2418 aum1701 auf2249 aua6615],
    :noAccess => ~w[aup9261 aup6836 aui9865 auj5680 auq9679],
    :unknown => ~w[unknownUser]
  }

  defmacro exs_fixture(file) do
    quote do
      Code.eval_file(unquote(file))
      |> Tuple.to_list()
      |> List.first()
    end
  end

  def prewarm_controlled_term_cache, do: MetadataGenerator.prewarm_cache()

  def test_users(category \\ :access), do: @test_users |> Map.get(category)
  def random_user(category \\ :access), do: category |> test_users |> Enum.random()
  def user_fixture(category \\ :access), do: category |> random_user() |> User.find()

  def seed_values(type) do
    "priv/repo/seeds/#{type}.json"
    |> File.read!()
    |> Jason.decode!(keys: :atoms)
  end

  def ingest_sheet_fixture(attrs \\ %{}) do
    project = project_fixture()
    title = "title-#{System.unique_integer([:positive])}"
    filename = "file-#{System.unique_integer([:positive])}.csv"

    attrs =
      Enum.into(attrs, %{
        title: attrs[:title] || title,
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
        title: attrs[:title] || "collection-#{System.unique_integer([:positive])}",
        description: attrs[:description] || "Description of collection",
        keywords: attrs[:keywords] || ["keyword1", "keyword 2", "keyword 3"]
      })

    {:ok, collection} =
      %Collection{}
      |> Collection.changeset(attrs)
      |> Repo.insert()

    collection
  end

  @spec batch_fixture(nil | maybe_improper_list | map) :: any
  def batch_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        nickname: attrs[:title] || "batch-#{System.unique_integer([:positive])}",
        query: ~s'{"query":{"term":{"workType.id": "IMAGE"}}}',
        replace:
          Jason.encode!(%{
            visibility: %{id: "OPEN", scheme: "VISIBILITY"}
          }),
        user: "user123",
        type: "update"
      })

    {:ok, batch} =
      %Batch{}
      |> Batch.changeset(attrs)
      |> Repo.insert()

    batch
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
      role: attrs[:role] || %{id: Faker.Util.pick(["A", "P", "S", "X"]), scheme: "FILE_SET_ROLE"},
      core_metadata:
        attrs[:core_metadata] ||
          %{
            description: attrs[:description] || Faker.String.base64(),
            location: "https://fake-s3-bucket/" <> Faker.String.base64(),
            original_filename: Faker.File.file_name()
          },
      extracted_metadata: attrs[:extracted_metadata] || %{},
      derivatives: attrs[:derivatives] || %{"playlist" => "s3://foo/bar.m3u8"}
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
        display_name: "User Name",
        role: "Administrator"
      }
    })
  end

  def delete_entry(dn) do
    with {:ok, conn} <- Exldap.connect() do
      :eldap.delete(conn, to_charlist(dn))
    end
  end

  def entry_names([]), do: []
  def entry_names(%Ldap.Entry{} = entry), do: entry.name
  def entry_names([entry | entries]), do: [entry_names(entry) | entry_names(entries)]
  def meadow_dn(cn), do: "CN=#{cn},OU=Meadow,OU=test,DC=library,DC=northwestern,DC=edu"
  def test_users_dn(cn), do: "CN=#{cn},OU=TestUsers,OU=test,DC=library,DC=northwestern,DC=edu"

  def logged?(string, :warn, pattern),
    do: logged?(string, ~r/^warn(ing)?$/, pattern)

  def logged?(string, level, pattern) when is_atom(level),
    do: logged?(string, Regex.compile!("^#{level}$"), pattern)

  def logged?(string, level, pattern) when is_binary(pattern),
    do: logged?(string, level, Regex.compile!(pattern))

  def logged?(string, level, pattern) do
    with lines <- String.split(string, ~r/\r?\n/) do
      Enum.any?(lines, fn line ->
        case Regex.named_captures(~r/\[(?<level>\w+?)\]\s+(?<message>.+)/, line) do
          %{"level" => found_level, "message" => found_message} ->
            String.match?(found_level, level) && String.match?(found_message, pattern)

          _ ->
            false
        end
      end)
    end
  end

  def mock_database_notification(listener, table, operation, ids, state \\ %{}) do
    listener.handle_info(
      {:notification, self(), self(), "#{table}_changed",
       Jason.encode!(%{source: "#{table}", operation: operation, ids: ids})},
      state
    )
  end

  defp uniqify_ingest_sheet_rows(csv) do
    with prefix <- test_id() do
      [headers | rows] = CSV.parse_string(csv, skip_headers: false)

      rows =
        rows
        |> Enum.map(&uniqify_ingest_sheet_row(&1, headers, prefix))

      [headers | rows]
      |> CSV.dump_to_iodata()
      |> IO.iodata_to_binary()
    end
  end

  defp uniqify_ingest_sheet_row(row, headers, prefix) do
    row
    |> Enum.with_index()
    |> Enum.map(fn {value, index} ->
      if headers |> Enum.at(index) |> String.contains?("accession_number") do
        [prefix, value] |> Enum.join("_")
      else
        value
      end
    end)
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
