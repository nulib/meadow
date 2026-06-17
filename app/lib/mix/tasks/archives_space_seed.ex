defmodule Mix.Tasks.Meadow.ArchivesSpace.Seed do
  @moduledoc """
  Populates an ArchivesSpace instance with image fixture data for testing the
  Meadow ingest workflow end to end.

  Mirrors the shape of Northwestern's production finding aids
  (findingaids.library.northwestern.edu), where collections are divided across
  several library repositories. This task creates three *fictional* library
  repositories so the local data has the same divided-by-repository structure
  without being mistaken for real Northwestern holdings.

  Each repository gets one finding aid (a resource with a series and several
  file-level archival objects). Each file-level object carries a digital object
  instance whose `file_version` points at a real, downloadable image, so
  importing the resource into Meadow produces works with access file sets that
  flow through the pipeline (and, for AI ingest, the image metadata agent).

  Intended for the local docker ArchivesSpace stack (see
  `infrastructure/archivesspace`), so it defaults to that instance's endpoint
  and credentials. Repositories are keyed by a stable `repo_code`, so rerunning
  reuses the same three repositories and adds another finding aid to each.

  ## Usage

      mix meadow.archives_space.seed [options]

  ## Options

    * `--url` - ArchivesSpace backend API URL (default: the `ARCHIVESSPACE_URL`
      environment variable, or `http://localhost:8089`). Point this at the same
      instance the dev server uses (start it with
      `ARCHIVESSPACE_URL=http://localhost:8089 iex -S mix phx.server`).
    * `--user` - ArchivesSpace user (default: `admin`)
    * `--password` - ArchivesSpace password (default: `admin`)
    * `--items` - number of file-level archival objects to create per finding
      aid (default: `5`)
    * `--image-urls` - comma-separated image URLs to attach as digital objects
      (default: a set of stable public photographs)

  ## Examples

      mix meadow.archives_space.seed
      mix meadow.archives_space.seed --items 10
      mix meadow.archives_space.seed --url http://localhost:8089
  """
  use Mix.Task

  alias Meadow.ArchivesSpace.Client

  @shortdoc "Populate a (dev) ArchivesSpace with image fixture data"

  @switches [
    url: :string,
    user: :string,
    password: :string,
    items: :integer,
    image_urls: :string
  ]

  @default_url "http://localhost:8089"
  @default_user "admin"
  @default_password "admin"
  @default_items 5

  # Fictional library repositories. The shape mirrors Northwestern's production
  # finding aids (collections divided across repositories like the Music Library,
  # University Archives, etc.), but the names are deliberately invented so devs
  # don't mistake the local fixtures for real Northwestern holdings.
  @repositories [
    %{
      repo_code: "meadow_fixture_photography",
      name: "Meadow Fixture Library of Photography (test data)",
      resource_title: "Fictional Photography Collection",
      resource_id: "MEADOW-FIXTURE-PHOTO",
      series_title: "Series I: Photographs",
      item_label: "Photograph",
      dates: "1965/1972",
      scope:
        "Fictional photographs assembled to exercise the Meadow ArchivesSpace " <>
          "ingest workflow. Not real Northwestern materials."
    },
    %{
      repo_code: "meadow_fixture_records",
      name: "Meadow Fixture University Records (test data)",
      resource_title: "Fictional Campus Records",
      resource_id: "MEADOW-FIXTURE-RECORDS",
      series_title: "Series I: Administrative Files",
      item_label: "File",
      dates: "1940/1989",
      scope:
        "Fictional administrative records assembled to exercise the Meadow " <>
          "ArchivesSpace ingest workflow. Not real Northwestern materials."
    },
    %{
      repo_code: "meadow_fixture_music",
      name: "Meadow Fixture Music & Audio Library (test data)",
      resource_title: "Fictional Performance Materials",
      resource_id: "MEADOW-FIXTURE-MUSIC",
      series_title: "Series I: Scores and Recordings",
      item_label: "Item",
      dates: "1955/1998",
      scope:
        "Fictional performance materials assembled to exercise the Meadow " <>
          "ArchivesSpace ingest workflow. Not real Northwestern materials."
    }
  ]

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

    images = image_urls(opts)
    count = opts[:items] || @default_items

    seeded =
      for spec <- @repositories do
        repo_uri = ensure_repository(spec)
        resource_uri = create_resource(repo_uri, spec)
        series_uri = create_series(repo_uri, resource_uri, spec)

        items =
          for index <- 1..count do
            image = Enum.at(images, rem(index - 1, length(images)))
            create_item(repo_uri, resource_uri, series_uri, spec, index, image)
          end

        %{repo_uri: repo_uri, resource_uri: resource_uri, items: items}
      end

    report(seeded)
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

  # Reuse the repository with this spec's repo_code if it already exists,
  # otherwise create it, so reruns add finding aids to the same repositories.
  defp ensure_repository(spec) do
    case Client.get("/repositories") do
      {:ok, %{status: 200, body: repos}} when is_list(repos) ->
        repos
        |> Enum.find(&(&1["repo_code"] == spec.repo_code))
        |> case do
          %{"uri" => uri} -> uri
          _ -> create_repository(spec)
        end

      _ ->
        create_repository(spec)
    end
  end

  defp create_repository(spec) do
    {:ok, uri} =
      Client.create_record("/repositories", %{
        "jsonmodel_type" => "repository",
        "repo_code" => spec.repo_code,
        "name" => spec.name
      })

    uri
  end

  defp create_resource(repo_uri, spec) do
    {:ok, uri} =
      Client.create_record("#{repo_uri}/resources", %{
        "jsonmodel_type" => "resource",
        "title" => "#{spec.resource_title} #{unique()}",
        "id_0" => "#{spec.resource_id}-#{unique()}",
        "level" => "collection",
        "publish" => true,
        "finding_aid_language" => "eng",
        "finding_aid_script" => "Latn",
        "ead_location" => "https://findingaids.example.edu/#{spec.repo_code}-#{unique()}",
        "lang_materials" => [language_eng()],
        "dates" => [single_date(spec.dates)],
        "extents" => [extent()],
        "notes" => [scopecontent_note(spec.scope)]
      })

    uri
  end

  defp create_series(repo_uri, resource_uri, spec) do
    {:ok, uri} =
      Client.create_record("#{repo_uri}/archival_objects", %{
        "jsonmodel_type" => "archival_object",
        "title" => spec.series_title,
        "level" => "series",
        "publish" => true,
        "resource" => %{"ref" => resource_uri}
      })

    uri
  end

  defp create_item(repo_uri, resource_uri, series_uri, spec, index, image_url) do
    digital_object_uri = create_digital_object(repo_uri, spec, index, image_url)

    {:ok, uri} =
      Client.create_record("#{repo_uri}/archival_objects", %{
        "jsonmodel_type" => "archival_object",
        "title" => "#{spec.item_label} #{index}",
        "level" => "file",
        "publish" => true,
        "resource" => %{"ref" => resource_uri},
        "parent" => %{"ref" => series_uri},
        "dates" => [single_date("19#{60 + index}")],
        "notes" => [
          scopecontent_note("#{spec.item_label} number #{index} from the test collection."),
          abstract_note("A test #{String.downcase(spec.item_label)} used to exercise the ingest pipeline.")
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

  defp create_digital_object(repo_uri, spec, index, image_url) do
    {:ok, uri} =
      Client.create_record("#{repo_uri}/digital_objects", %{
        "jsonmodel_type" => "digital_object",
        "digital_object_id" => "#{spec.repo_code}-#{unique()}-#{index}",
        "title" => "#{spec.item_label} #{index} (digital object)",
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

  defp report(seeded) do
    repos =
      seeded
      |> Enum.map_join("\n", fn %{repo_uri: repo_uri, resource_uri: resource_uri, items: items} ->
        """
          Repository: #{repo_uri}
            Resource: #{resource_uri} (#{length(items)} file-level archival objects)
            Import it with: mix meadow.archives_space.import #{resource_uri}
        """
      end)

    Mix.shell().info("""

    Seeded ArchivesSpace with fictional, divided-by-repository image fixtures:

    #{repos}
    """)
  end

  defp unique, do: System.unique_integer([:positive])
end
