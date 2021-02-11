defmodule MigrationOptions do
  @moduledoc """
  Parse options for migration tasks
  """

  require Logger

  @log_levels ~w(emergency alert critical error warning notice info debug)
  @opts [
    binary_bucket: :string,
    log_level: :string,
    migration_bucket: :string,
    since: :string,
    max: :integer
  ]

  def initialize(args) do
    System.put_env("MEADOW_PROCESSES", "none")
    Mix.Task.run("app.start")

    Logger.configure(level: :info)

    with {opts, _, _} <- OptionParser.parse(args, strict: @opts) do
      Enum.map(opts, fn
        {:binary_bucket, value} ->
          Application.put_env(:meadow, :migration_binary_bucket, value)
          nil

        {:migration_bucket, value} ->
          Application.put_env(:meadow, :migration_manifest_bucket, value)
          nil

        {:log_level, value} ->
          if Enum.member?(@log_levels, value),
            do: Logger.configure(level: String.to_atom(value)),
            else: raise("Unknown log level: #{value}")

          nil

        {:max, value} ->
          {:max, value}

        {:since, value} ->
          case DateTime.from_iso8601(value) do
            {:ok, since, _} -> {:since, since}
            {:error, error} -> raise "Cannot parse #{value}: #{error}"
          end

        _ ->
          nil
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.into(%{max: :all, since: nil})
    end
  end
end

defmodule Mix.Tasks.Migration.Reset do
  @moduledoc "Clear the donut_works table"

  use Mix.Task
  alias Meadow.Data.DonutWorks
  require Logger

  @shortdoc @moduledoc
  def run(args) do
    MigrationOptions.initialize(args)
    DonutWorks.reset!()
  end
end

defmodule Mix.Tasks.Migration.Initialize do
  @moduledoc """
  Load migration manifests from S3 into Meadow

  ## Command line options

    * `--log-level` - override the log level (default: `info`)
    * `--migration-bucket` - override the name of the bucket to import manifests from
    * `--since` - ignore all manifests older than this ISO8601 timestamp
  """
  use Mix.Task
  alias Meadow.{Config, Migration}
  require Logger

  @shortdoc "Load migration manifests from S3 into Meadow"
  def run(args) do
    with %{since: since} <- MigrationOptions.initialize(args),
         bucket <- Config.migration_manifest_bucket() do
      if is_nil(since),
        do: Logger.info("Importing all manifests from #{bucket}"),
        else: Logger.info("Importing manifests newer than #{since} from #{bucket}")

      Migration.import(since)
    end
  end
end

defmodule Mix.Tasks.Migration.Precache do
  @moduledoc """
  Pre-cache all authorities for pending manifests
  """
  use Mix.Task
  alias Meadow.Migration
  require Logger

  @shortdoc @moduledoc
  def run(args) do
    MigrationOptions.initialize(args)
    Migration.cache_authorities()
  end
end

defmodule Mix.Tasks.Migration.Run do
  @moduledoc """
  Run all pre-loaded Donut migrations

  ## Command line options

    * `--log-level` - override the log level (default: `info`)
    * `--binary-bucket` - override the name of the bucket to import master files from
    * `--max` - maximum number of manifests (works) to import in a single run
  """
  use Mix.Task
  alias Meadow.Data.Indexer
  alias Meadow.Migration
  require Logger

  @shortdoc "Run all pre-loaded Donut migrations"
  def run(args) do
    with %{max: max} <- MigrationOptions.initialize(args) do
      Migration.migrate(max)
    end

    Indexer.synchronize_index()
  end
end

defmodule Mix.Tasks.Migration.ImportCollections do
  @moduledoc """
  Import collections from DONUT

  Requires DONUT_COOKIE to be set with the value of a valid `_nextgen_session`
  cookie from DONUT
  """
  use Mix.Task
  alias Meadow.Data.Collections
  alias Meadow.Data.Schemas.Collection
  alias Meadow.Repo
  import Ecto.Query
  require Logger

  @shortdoc "Import collections from DONUT"
  def run(args) do
    MigrationOptions.initialize(args)

    case System.get_env("DONUT_COOKIE") do
      nil -> Logger.error("DONUT_COOKIE not found")
      session_cookie -> make_collections(session_cookie)
    end
  end

  defp make_collection(%{id: id, title_tesim: [title | _]} = doc) do
    if Collection |> where([c], c.id == ^id) |> Repo.exists?() do
      Logger.warn("Skipping collection #{id} (#{title}) because it already exists")
    else
      attributes = %{
        id: id,
        title: title,
        visibility: %{
          id: doc |> Map.get(:visibility_ssi) |> String.upcase(),
          scheme: "VISIBILITY"
        },
        published: true,
        keywords:
          case Map.get(doc, :keyword_tesim) do
            nil -> []
            keywords -> keywords
          end,
        description:
          case Map.get(doc, :description_tesim) do
            nil -> ""
            [] -> ""
            [description | _] -> description
          end
      }

      case Collections.create_collection(attributes) do
        {:ok, collection} ->
          Logger.info("Imported collection #{id} (#{collection.title})")

        {:error, error} ->
          Logger.warn("Unable to import collection #{id} (#{title}): #{inspect(error)}")
      end
    end
  end

  defp make_collections(session_cookie) do
    HTTPoison.get!(
      "https://donut.library.northwestern.edu/catalog.json",
      [cookie: "_nextgen_session=#{session_cookie}"],
      params: [
        {"f[human_readable_type_sim][]", "Collection"},
        {"locale", "en"},
        {"f[collection_type_gid_ssim][]", "gid://nextgen/hyrax-collectiontype/3"},
        {"per_page", "100"}
      ]
    )
    |> Map.get(:body)
    |> Jason.decode!(keys: :atoms)
    |> get_in([:response, :docs])
    |> Enum.each(&make_collection/1)
  end
end
