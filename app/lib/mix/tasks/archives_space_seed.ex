defmodule Mix.Tasks.Meadow.ArchivesSpace.Seed do
  @moduledoc """
  Populates an ArchivesSpace instance with image fixture data for testing the
  Meadow ingest workflow end to end.

  Creates a resource (finding aid) with a series and several file-level
  archival objects. Each file-level object carries a digital object instance
  whose `file_version` points at a real, downloadable image, so importing the
  resource into Meadow produces works with access file sets that flow through
  the pipeline (and, for AI ingest, the image metadata agent).

  Intended for the local docker ArchivesSpace stack (see
  `infrastructure/archivesspace`), so it defaults to that instance's endpoint
  and credentials. Each run creates a brand new resource.

  ## Usage

      mix meadow.archives_space.seed [options]

  ## Options

    * `--url` - ArchivesSpace backend API URL (default: the `ARCHIVESSPACE_URL`
      environment variable, or `http://localhost:8089`). Point this at the same
      instance the dev server uses (start it with
      `ARCHIVESSPACE_URL=http://localhost:8089 iex -S mix phx.server`).
    * `--user` - ArchivesSpace user (default: `admin`)
    * `--password` - ArchivesSpace password (default: `admin`)
    * `--repo` - existing repository URI to seed into (default: the first
      repository found, or a new one)
    * `--items` - number of file-level archival objects to create (default: `5`)
    * `--image-urls` - comma-separated image URLs to attach as digital objects
      (default: a set of stable public photographs)

  ## Examples

      mix meadow.archives_space.seed
      mix meadow.archives_space.seed --items 10
      mix meadow.archives_space.seed --url http://localhost:8089 --repo /repositories/2
  """
  use Mix.Task

  alias Meadow.ArchivesSpace.Client

  @shortdoc "Populate a (dev) ArchivesSpace with image fixture data"

  @switches [
    url: :string,
    user: :string,
    password: :string,
    repo: :string,
    items: :integer,
    image_urls: :string
  ]

  @default_url "http://localhost:8089"
  @default_user "admin"
  @default_password "admin"
  @default_items 5

  # Stable, public photographs (deterministic per id) used as digital object
  # images so the imported works have real content for the pipeline and the
  # AI metadata agent to work with.
  @default_image_urls [
    "https://iiif.dc.library.northwestern.edu/iiif/3/7aae87f7-c7f7-4b93-a423-313717a6f064/full/!1200,1200/0/default.jpg",
    "https://iiif.dc.library.northwestern.edu/iiif/3/2fb1e81a-9e24-420c-b224-0bfd6a279baf/full/!1200,1200/0/default.jpg",
    "https://iiif.dc.library.northwestern.edu/iiif/3/8d67859f-fc5d-4c8c-9cbb-04c4da3ffab8/full/!1200,1200/0/default.jpg",
    "https://iiif.dc.library.northwestern.edu/iiif/3/6884ac8a-3c91-456e-9221-182eef80fe6e/full/!1200,1200/0/default.jpg",
    "https://iiif.dc.library.northwestern.edu/iiif/3/b288888e-2755-4fe3-b381-741fe71b34c4/full/!1200,1200/0/default.jpg"
  ]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    case OptionParser.parse(args, strict: @switches) do
      {opts, [], []} ->
        seed(opts)

      {_, _, invalid} when invalid != [] ->
        Mix.raise("Invalid options: #{inspect(invalid)}")

      {_, extra, _} ->
        Mix.raise("Unexpected arguments: #{inspect(extra)} (this task takes options only)")
    end
  end

  defp seed(opts) do
    configure_client(opts)

    repo_uri = opts[:repo] || ensure_repository()
    images = image_urls(opts)
    count = opts[:items] || @default_items

    resource_uri = create_resource(repo_uri)
    series_uri = create_series(repo_uri, resource_uri)

    items =
      for index <- 1..count do
        image = Enum.at(images, rem(index - 1, length(images)))
        create_item(repo_uri, resource_uri, series_uri, index, image)
      end

    report(repo_uri, resource_uri, items)
  end

  # Point the ArchivesSpace client at the requested instance for this run.
  defp configure_client(opts) do
    url = opts[:url] || System.get_env("ARCHIVESSPACE_URL", @default_url)

    Application.put_env(:meadow, :archives_space, %{
      url: url,
      user: opts[:user] || @default_user,
      password: opts[:password] || @default_password
    })

    Client.invalidate_session()

    case Client.session_token() do
      {:ok, _token} ->
        :ok

      {:error, reason} ->
        Mix.raise("""
        Could not authenticate to ArchivesSpace at #{url}: #{inspect(reason)}
        Is the instance running? Start the docker stack with:
          make -C infrastructure/archivesspace wait
        """)
    end
  end

  defp image_urls(opts) do
    case opts[:image_urls] do
      nil -> @default_image_urls
      urls -> String.split(urls, ",", trim: true)
    end
  end

  defp ensure_repository do
    case Client.get("/repositories") do
      {:ok, %{status: 200, body: repos}} when is_list(repos) ->
        repos
        |> Enum.map(& &1["uri"])
        |> Enum.find(&(is_binary(&1) and Regex.match?(~r{^/repositories/\d+$}, &1)))
        |> case do
          nil -> create_repository()
          uri -> uri
        end

      _ ->
        create_repository()
    end
  end

  defp create_repository do
    {:ok, uri} =
      Client.create_record("/repositories", %{
        "jsonmodel_type" => "repository",
        "repo_code" => "meadow_seed_#{unique()}",
        "name" => "Meadow Seed Fixtures"
      })

    uri
  end

  defp create_resource(repo_uri) do
    {:ok, uri} =
      Client.create_record("#{repo_uri}/resources", %{
        "jsonmodel_type" => "resource",
        "title" => "Meadow Test Collection #{unique()}",
        "id_0" => "MEADOW-SEED-#{unique()}",
        "level" => "collection",
        "publish" => true,
        "finding_aid_language" => "eng",
        "finding_aid_script" => "Latn",
        "ead_location" => "https://findingaids.example.edu/meadow-seed-#{unique()}",
        "lang_materials" => [language_eng()],
        "dates" => [single_date("1965/1972")],
        "extents" => [extent()],
        "notes" => [
          scopecontent_note(
            "Photographs, correspondence, and ephemera assembled for testing the " <>
              "Meadow ArchivesSpace ingest workflow."
          )
        ]
      })

    uri
  end

  defp create_series(repo_uri, resource_uri) do
    {:ok, uri} =
      Client.create_record("#{repo_uri}/archival_objects", %{
        "jsonmodel_type" => "archival_object",
        "title" => "Series I: Photographs",
        "level" => "series",
        "publish" => true,
        "resource" => %{"ref" => resource_uri}
      })

    uri
  end

  defp create_item(repo_uri, resource_uri, series_uri, index, image_url) do
    digital_object_uri = create_digital_object(repo_uri, index, image_url)

    {:ok, uri} =
      Client.create_record("#{repo_uri}/archival_objects", %{
        "jsonmodel_type" => "archival_object",
        "title" => "Photograph #{index}",
        "level" => "file",
        "publish" => true,
        "resource" => %{"ref" => resource_uri},
        "parent" => %{"ref" => series_uri},
        "dates" => [single_date("19#{60 + index}")],
        "notes" => [
          scopecontent_note("Photograph number #{index} from the test collection."),
          abstract_note("A test photograph used to exercise the ingest pipeline.")
        ],
        "instances" => [
          %{
            "jsonmodel_type" => "instance",
            "instance_type" => "digital_object",
            "digital_object" => %{"ref" => digital_object_uri}
          }
        ]
      })

    uri
  end

  defp create_digital_object(repo_uri, index, image_url) do
    {:ok, uri} =
      Client.create_record("#{repo_uri}/digital_objects", %{
        "jsonmodel_type" => "digital_object",
        "digital_object_id" => "meadow-seed-#{unique()}-#{index}",
        "title" => "Photograph #{index} (digital object)",
        "publish" => true,
        "file_versions" => [
          %{
            "jsonmodel_type" => "file_version",
            "file_uri" => image_url,
            "publish" => true,
            "use_statement" => "image-service"
          }
        ]
      })

    uri
  end

  defp language_eng do
    %{
      "jsonmodel_type" => "lang_material",
      "language_and_script" => %{
        "jsonmodel_type" => "language_and_script",
        "language" => "eng"
      }
    }
  end

  defp single_date(expression) do
    %{
      "jsonmodel_type" => "date",
      "date_type" => "single",
      "label" => "creation",
      "expression" => expression
    }
  end

  defp extent do
    %{
      "jsonmodel_type" => "extent",
      "portion" => "whole",
      "number" => "1",
      "extent_type" => "linear_feet"
    }
  end

  defp scopecontent_note(content) do
    %{
      "jsonmodel_type" => "note_multipart",
      "type" => "scopecontent",
      "publish" => true,
      "subnotes" => [
        %{"jsonmodel_type" => "note_text", "content" => content, "publish" => true}
      ]
    }
  end

  defp abstract_note(content) do
    %{
      "jsonmodel_type" => "note_singlepart",
      "type" => "abstract",
      "publish" => true,
      "content" => [content]
    }
  end

  defp report(repo_uri, resource_uri, items) do
    Mix.shell().info("""

    Seeded ArchivesSpace with image fixtures:
      Repository: #{repo_uri}
      Resource:   #{resource_uri}
      File-level archival objects (with image digital objects): #{length(items)}

    Import it into Meadow with:
      mix meadow.archives_space.import #{resource_uri}
    """)
  end

  defp unique, do: System.unique_integer([:positive])
end
