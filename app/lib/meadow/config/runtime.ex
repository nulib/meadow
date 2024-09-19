defmodule Meadow.Config.Runtime do
  @moduledoc """
  Load and apply Meadow's runtime configuration
  """

  alias Meadow.Config.Pipeline

  @config_map %{
    meadow: "config/meadow",
    inference: "infrastructure/inference",
    index: "infrastructure/index",
    ldap: "infrastructure/ldap",
    iiif: "infrastructure/iiif",
    honeybadger: "infrastructure/honeybadger",
    nusso: "infrastructure/nusso",
    wildcard_ssl: "config/wildcard_ssl"
  }

  # TODO: UPDATE ALL get_secret(:meadow, ["dc",...]) to use DC secrets

  def configure! do
    case :ets.info(:secret_cache, :name) do
      :secret_cache -> :ets.delete_all_objects(:secret_cache)
      :undefined -> :ets.new(:secret_cache, [:set, :protected, :named_table])
    end

    import Config

    [:hackney, :ex_aws] |> Enum.each(&Application.ensure_all_started/1)

    dc_base =
      get_secret(
        :meadow,
        ["dc", "base_url"],
        "https://dc.rdc-staging.library.northwestern.edu"
      )

    config :authoritex, geonames_username: get_secret(:meadow, ["geonames", "username"])

    config :elastix,
      custom_headers: {Meadow.Utils.AWS, :add_aws_signature, []}

    config :exldap, :settings,
      server: get_secret(:ldap, ["host"]),
      base: get_secret(:ldap, ["base"]),
      port: get_secret(:ldap, ["port"]),
      user_dn: get_secret(:ldap, ["user_dn"]),
      password: get_secret(:ldap, ["password"]),
      ssl: get_secret(:ldap, ["ssl"]) == "true"

    config :hackney,
      max_connections: environment_int("HACKNEY_MAX_CONNECTIONS", 1000)

    config :honeybadger,
      api_key: get_secret(:honeybadger, ["api_key"], "DO_NOT_REPORT"),
      environment_name: get_secret(:honeybadger, ["environment"], to_string(Mix.env())),
      revision: System.get_env("HONEYBADGER_REVISION", ""),
      repos: [Meadow.Repo],
      breadcrumbs_enabled: true,
      filter: Meadow.Error.Filter,
      exclude_envs: [:dev, :test]

    config :meadow, Meadow.Repo,
      username: get_secret(:meadow, ["db", "user"]),
      password: get_secret(:meadow, ["db", "password"]),
      database: get_secret(:meadow, ["db", "database"], prefix("meadow")),
      hostname: get_secret(:meadow, ["db", "host"]),
      port: get_secret(:meadow, ["db", "port"]),
      pool_size: environment_int("DB_POOL_SIZE", 10),
      queue_target: environment_int("DB_QUEUE_TARGET", 50),
      queue_interval: environment_int("DB_QUEUE_INTERVAL", 1000)

    host = System.get_env("MEADOW_HOSTNAME", "example.com")
    port = environment_int("PORT", 4000)

    config :meadow, MeadowWeb.Endpoint,
      url: [host: host, port: port],
      http: [
        :inet6,
        port: port,
        protocol_options: [
          idle_timeout: :infinity,
          max_header_value_length: 8192
        ]
      ],
      check_origin: System.get_env("ALLOWED_ORIGINS", "") |> String.split(~r/,\s*/),
      secret_key_base: System.get_env("SECRET_KEY_BASE"),
      live_view: [signing_salt: System.get_env("SECRET_KEY_BASE")]

    config :meadow, Meadow.Search.Cluster,
      url: get_secret(:meadow, ["index", "index_endpoint"]),
      default_options: [
        timeout: 20_000,
        recv_timeout: 90_000
      ],
      bulk_page_size: 200,
      bulk_wait_interval: 500,
      indexes: [
        %{
          name: prefix("dc-v2-work"),
          settings: priv_path("search/v2/settings/work.json"),
          version: 2,
          schemas: [Meadow.Data.Schemas.Work],
          pipeline: prefix("dc-v2-work-pipeline")
        },
        %{
          name: prefix("dc-v2-file-set"),
          settings: priv_path("search/v2/settings/file_set.json"),
          version: 2,
          schemas: [Meadow.Data.Schemas.FileSet]
        },
        %{
          name: prefix("dc-v2-collection"),
          settings: priv_path("search/v2/settings/collection.json"),
          version: 2,
          schemas: [Meadow.Data.Schemas.Collection]
        }
      ],
      embedding_model_id: get_secret(:index, ["models", "default"]),
      # TODO: MOVE embedding_dimensions TO INDEX SECRET
      embedding_dimensions: get_secret(:meadow, ["index", "embedding_dimensions"])

    config :meadow,
      ark: %{
        default_shoulder: get_secret(:ezid, ["shoulder"], "ark:/12345/nu1"),
        user: get_secret(:ezid, ["user"], "ark_user"),
        password: get_secret(:ezid, ["password"], "ark_password"),
        target_url:
          get_secret(
            :meadow,
            ["ezid", "target_base_url"],
            "https://devbox.library.northwestern.edu:3333/items/"
          ),
        url: get_secret(:ezid, ["url"], default: "http://localhost:3943")
      }

    config :meadow,
      # TODO: REPLACE WITH DC API SECRET
      dc_api: [v2: get_secret(:meadow, ["dc_api", "v2"])],
      digital_collections_url:
        get_secret(
          :meadow,
          ["dc", "base_url"],
          "https://dc.rdc-staging.library.northwestern.edu/"
        ),
      environment: environment(),
      environment_prefix: prefix(),
      iiif_server_url:
        get_secret(:iiif, ["v3"],
          default: "https://iiif.dev.rdc.library.northwestern.edu/iiif/3/#{prefix()}"
        ),
      iiif_manifest_url_deprecated:
        Path.join(
          get_secret(:iiif, ["base"], "https://#{prefix()}-pyramids.s3.amazonaws.com/"),
          "public/"
        ),
      iiif_distribution_id: get_secret(:iiif, ["distribution_id"]),
      mediaconvert_client: MediaConvert,
      mediaconvert_queue: get_secret(:meadow, ["mediaconvert", "queue"]),
      mediaconvert_role: get_secret(:meadow, ["mediaconvert", "role_arn"]),
      multipart_upload_concurrency: environment_int("MULTIPART_UPLOAD_CONCURRENCY", 50),
      pipeline_delay: environment_int("PIPELINE_DELAY", 120_000),
      progress_ping_interval: environment_int("PROGRESS_PING_INTERVAL", 1000),
      pyramid_tiff_working_dir: System.tmp_dir!(),
      shared_links_index: prefix("shared_links"),
      sitemaps: [
        gzip: true,
        store: Sitemapper.S3Store,
        store_config: [
          bucket: get_secret(:meadow, ["buckets", "sitemap"]),
          path: "/"
        ],
        base_url: dc_base,
        sitemap_url: Path.join(dc_base, "api/sitemap")
      ],
      streaming_distribution_id: get_secret(:meadow, ["streaming", "distribution_id"]),
      streaming_url:
        get_secret(
          :meadow,
          ["streaming", "base_url"],
          "https://#{prefix()}-streaming.s3.amazonaws.com/"
        ),
      validation_ping_interval: environment_int("VALIDATION_PING_INTERVAL", 1000),
      # TODO: UPDATE TO READ FROM API'S SECRETS
      work_archiver_endpoint: get_secret(:meadow, ["work_archiver", "endpoint"], "")

    config :meadow,
      ingest_bucket: get_secret(:meadow, ["buckets", "ingest"], prefix("ingest")),
      preservation_bucket:
        get_secret(:meadow, ["buckets", "preservation"], prefix("preservation")),
      pyramid_bucket: get_secret(:meadow, ["buckets", "pyramid"], prefix("pyramid")),
      upload_bucket: get_secret(:meadow, ["buckets", "upload"], prefix("upload")),
      preservation_check_bucket:
        get_secret(:meadow, ["buckets", "preservation_check"], prefix("preservation-checks")),
      streaming_bucket: get_secret(:meadow, ["buckets", "streaming"], prefix("streaming"))

    config :meadow, :lambda,
      digester: {:lambda, get_secret(:meadow, ["pipeline", "digester"], "digester:$LATEST")},
      exif: {:lambda, get_secret(:meadow, ["pipeline", "exif"], "exif:$LATEST")},
      frame_extractor:
        {:lambda, get_secret(:meadow, ["pipeline", "frame_extractor"], "frame-extractor:$LATEST")},
      mediainfo: {:lambda, get_secret(:meadow, ["pipeline", "mediainfo"], "mediainfo:$LATEST")},
      mime_type: {:lambda, get_secret(:meadow, ["pipeline", "mime_type"], "mime-type:$LATEST")},
      tiff: {:lambda, get_secret(:meadow, ["pipeline", "tiff"], "pyramid-tiff:$LATEST")}

    config :meadow, :livebook, url: System.get_env("LIVEBOOK_URL")

    config :meadow, Meadow.Scheduler,
      overlap: false,
      timezone: "America/Chicago",
      jobs: [
        # Sitemap generation runs daily at the configured time (default: 1AM Central)
        {
          get_secret(:meadow, ["scheduler", "sitemap"], "0 1 * * *"),
          {Meadow.Utils.Sitemap, :generate, []}
        },
        # Preservation check runs daily at the configured time (default: 2AM Central)
        {
          get_secret(:meadow, ["scheduler", "preservation_check"], "0 2 * * *"),
          {Meadow.Data.PreservationChecks, :start_job, []}
        }
      ]

    config :ueberauth, Ueberauth,
      providers: [
        nusso:
          {Ueberauth.Strategy.NuSSO,
           [
             base_url:
               get_secret(
                 :nusso,
                 ["base_url"],
                 "https://northwestern-prod.apigee.net/agentless-websso/"
               ),
             callback_path: "/auth/nusso/callback",
             consumer_key: get_secret(:nusso, ["api_key"]),
             include_attributes: false
           ]}
      ]

    Pipeline.configure!(prefix())

    with mod <- environment() |> to_string() |> String.capitalize() do
      Module.concat(__MODULE__, mod).configure!()
    end

    if :code.is_loaded(Mix) do
      file = Path.join(File.cwd!(), "config/#{Mix.env()}.local.exs")
      if File.exists?(file), do: Code.eval_file(file)
    end

    :ok
  end

  def get_secret(config, path, default \\ nil) do
    secrets =
      case :ets.lookup(:secret_cache, config) |> Keyword.get(config) do
        nil ->
          loaded = load_config(@config_map[config])
          :ets.insert(:secret_cache, {config, loaded})
          loaded

        value ->
          value
      end

    case get_in(secrets, path) do
      nil -> default
      secret -> secret
    end
  end

  defp load_config(config_path) do
    System.get_env("CONFIG_PREFIX", nil) |> load_config(config_path)
  end

  defp load_config(nil, config_path), do: retrieve_config(config_path)

  defp load_config(prefix, config_path),
    do: Path.join(Enum.reject([prefix, config_path], &is_nil/1)) |> retrieve_config()

  defp retrieve_config(path) do
    case ExAws.SecretsManager.get_secret_value(path) |> ExAws.request() do
      {:ok, %{"SecretString" => secret_string}} -> Jason.decode!(secret_string)
      {:error, _} -> nil
    end
  end

  def environment do
    if function_exported?(Mix, :env, 0), do: Mix.env(), else: :prod
  end

  def prefix do
    env =
      cond do
        System.get_env("RELEASE_NAME") -> nil
        function_exported?(Mix, :env, 0) -> Mix.env()
        true -> nil
      end

    [System.get_env("DEV_PREFIX"), env] |> Enum.reject(&is_nil/1) |> Enum.join("-")
  end

  def prefix(val), do: [prefix(), to_string(val)] |> reject_empty() |> Enum.join("-")
  #  defp atom_prefix(val), do: prefix(val) |> String.to_atom()
  defp reject_empty(list), do: Enum.reject(list, &(is_nil(&1) or &1 == ""))

  defp environment_int(key, default) do
    case System.get_env(key) do
      nil -> default
      val -> String.to_integer(val)
    end
  end

  defp priv_path(path) do
    case :code.priv_dir(:meadow) do
      {:error, :bad_name} -> Path.join([".", "priv", path])
      priv_dir -> priv_dir |> to_string() |> Path.join(path)
    end
  end
end
