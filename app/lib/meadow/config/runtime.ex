defmodule Meadow.Config.Runtime do
  @moduledoc """
  Load and apply Meadow's runtime configuration
  """

  import Meadow.Config.Secrets

  require Logger

  # TODO: UPDATE ALL get_secret(:meadow, ["dc",...]) to use DC secrets

  def configure! do
    import Config

    clear_cache!()
    [:hackney, :ex_aws] |> Enum.each(&Application.ensure_all_started/1)

    dc_base =
      get_secret(
        :meadow,
        ["dc", "base_url"],
        "https://dc.rdc-staging.library.northwestern.edu"
      )

    Logger.info("Configuring authoritex")
    config :authoritex, geonames_username: get_secret(:meadow, ["geonames", "username"])

    Logger.info("Configuring elastix")

    config :elastix,
      custom_headers: {Meadow.Utils.AWS, :add_aws_signature, []}

    Logger.info("Configuring exldap")

    config :exldap, :settings,
      server: get_secret(:ldap, ["host"]),
      base: get_secret(:ldap, ["base"]),
      port: get_secret(:ldap, ["port"]),
      user_dn: get_secret(:ldap, ["user_dn"]),
      password: get_secret(:ldap, ["password"]),
      ssl: get_secret(:ldap, ["ssl"], "true") == "true"

    Logger.info("Configuring hackney")

    config :hackney,
      max_connections: environment_int("HACKNEY_MAX_CONNECTIONS", 1000)

    Logger.info("Configuring honeybadger")

    config :honeybadger,
      api_key: get_secret(:meadow, ["honeybadger", "api_key"], "DO_NOT_REPORT"),
      environment_name:
        get_secret(:meadow, ["honeybadger", "environment"], to_string(environment())),
      revision: System.get_env("HONEYBADGER_REVISION", ""),
      repos: [Meadow.Repo],
      breadcrumbs_enabled: true,
      filter: Meadow.Error.Filter,
      exclude_envs: [:dev, :test]

    Logger.info("Configuring Meadow.Repo")

    config :meadow, Meadow.Repo.Indexing,
      username: get_secret(:meadow, ["db", "user"]),
      password: get_secret(:meadow, ["db", "password"]),
      database: get_secret(:meadow, ["db", "database"], prefix("meadow")),
      hostname: get_secret(:meadow, ["db", "host"]),
      port: get_secret(:meadow, ["db", "port"]),
      pool_size: 5,
      queue_target: environment_int("DB_QUEUE_TARGET", 50),
      queue_interval: environment_int("DB_QUEUE_INTERVAL", 1000)

    config :meadow, Meadow.Repo,
      username: get_secret(:meadow, ["db", "user"]),
      password: get_secret(:meadow, ["db", "password"]),
      database: get_secret(:meadow, ["db", "database"], prefix("meadow")),
      hostname: get_secret(:meadow, ["db", "host"]),
      migration_primary_key: [
        name: :id,
        type: :binary_id,
        autogenerate: false,
        read_after_writes: true,
        default: {:fragment, "uuid_generate_v4()"}
      ],
      migration_timestamps: [type: :utc_datetime_usec],
      port: get_secret(:meadow, ["db", "port"]),
      pool_size: environment_int("DB_POOL_SIZE", 10) - 5,
      queue_target: environment_int("DB_QUEUE_TARGET", 50),
      queue_interval: environment_int("DB_QUEUE_INTERVAL", 1000)

    Logger.info("Configuring WalEx")

    config :meadow, WalEx,
      hostname: get_secret(:meadow, ["db", "host"]),
      username: get_secret(:meadow, ["db", "user"]),
      password: get_secret(:meadow, ["db", "password"]),
      database: get_secret(:meadow, ["db", "database"], prefix("meadow")),
      port: get_secret(:meadow, ["db", "port"]),
      publication: "events",
      subscriptions: ["works", "file_sets", "collections", "ingest_sheets", "projects"],
      name: Meadow,
      slot_name: "meadow_#{prefix()}",
      durable_slot: true

    host = System.get_env("MEADOW_HOSTNAME", "localhost")
    port = environment_int("PORT", 4000)

    Logger.info("Configuring MeadowWeb.Endpoint")

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
      live_view: [signing_salt: System.get_env("SECRET_KEY_BASE")],
      render_errors: [view: MeadowWeb.ErrorView, accepts: ~w(html json)],
      pubsub_server: Meadow.PubSub

    Logger.info("Configuring Meadow.Search.Cluster")

    config :meadow, Meadow.Search.Cluster,
      url: get_secret(:index, ["endpoint"]),
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
      embedding_model_id: get_secret(:index, ["embedding_model"]),
      # TODO: MOVE embedding_dimensions TO INDEX SECRET
      embedding_dimensions: get_secret(:index, ["embedding_dimensions"]),
      embedding_text_fields: [
        :title,
        :alternate_title,
        :description,
        :collection,
        :creator,
        :contributor,
        :date_created,
        :genre,
        :subject,
        :style_period,
        :language,
        :location,
        :publisher,
        :technique,
        :physical_description_material,
        :physical_description_size,
        :caption,
        :table_of_contents,
        :scope_and_contents,
        :abstract
      ]

    Logger.info("Configuring EZID")

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
        url: get_secret(:ezid, ["url"], "http://localhost:3943")
      }

    Logger.info("Configuring general meadow properties")

    config :meadow,
      # TODO: REPLACE WITH DC API SECRET
      dc_api: [
        v2: %{
          "api_token_secret" => get_secret(:dcapi, ["api_token_secret"]),
          "api_token_ttl" => get_secret(:dcapi, ["api_token_ttl"], 300),
          "base_url" => get_secret(:dcapi, ["base_url"])
        }
      ],
      digital_collections_url:
        get_secret(
          :meadow,
          ["dc", "base_url"],
          "https://dc.rdc-staging.library.northwestern.edu/"
        ),
      environment: environment(),
      environment_prefix: prefix(),
      iiif_server_url:
        get_secret(
          :iiif,
          ["v3"]
        ),
      iiif_manifest_url_deprecated:
        Path.join(
          get_secret(:iiif, ["base"]),
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
      required_checksum_tags: ["computed-md5"],
      checksum_wait_timeout: 3_600_000,
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
      transcoding_presets: %{
        audio: [
          %{NameModifier: "-high", Preset: "meadow-audio-high"},
          %{NameModifier: "-medium", Preset: "meadow-audio-medium"}
        ],
        video: [
          %{NameModifier: "-1080", Preset: "meadow-video-high"},
          %{NameModifier: "-720", Preset: "meadow-video-medium"},
          %{NameModifier: "-540", Preset: "meadow-video-low"}
        ]
      },
      validation_ping_interval: environment_int("VALIDATION_PING_INTERVAL", 1000),
      # TODO: UPDATE TO READ FROM API'S SECRETS
      work_archiver_endpoint: get_secret(:meadow, ["work_archiver", "endpoint"], "")

    Logger.info("Configuring meadow S3 buckets")
    config :meadow, buckets()

    Logger.info("Configuring meadow lambdas")

    config :meadow, :lambda,
      digester: {:lambda, get_secret(:meadow, ["pipeline", "digester"], "digester:$LATEST")},
      exif: {:lambda, get_secret(:meadow, ["pipeline", "exif"], "exif:$LATEST")},
      frame_extractor:
        {:lambda, get_secret(:meadow, ["pipeline", "frame_extractor"], "frame-extractor:$LATEST")},
      mediainfo: {:lambda, get_secret(:meadow, ["pipeline", "mediainfo"], "mediainfo:$LATEST")},
      mime_type: {:lambda, get_secret(:meadow, ["pipeline", "mime_type"], "mime-type:$LATEST")},
      tiff: {:lambda, get_secret(:meadow, ["pipeline", "tiff"], "pyramid-tiff:$LATEST")}

    config :meadow, :livebook, url: System.get_env("LIVEBOOK_URL")

    Logger.info("Configuring Meadow.Scheduler")

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

    Logger.info("Configuring ueberauth for NU SSO")

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

    with mod <- environment() |> to_string() |> String.capitalize() do
      Logger.info("Configuring #{mod} environment")
      Module.concat(__MODULE__, mod).configure!()
    end

    if :code.is_loaded(Mix) do
      file = Path.join(File.cwd!(), "config/#{Mix.env()}.local.exs")

      if File.exists?(file) do
        Logger.info("Loading config from #{Mix.env()}.local.exs")
        Code.eval_file(file)
      end
    end

    :ok
  end

  def buckets do
    [
      ingest_bucket: get_secret(:meadow, ["buckets", "ingest"], prefix("ingest")),
      preservation_bucket:
        get_secret(:meadow, ["buckets", "preservation"], prefix("preservation")),
      pyramid_bucket: get_secret(:meadow, ["buckets", "pyramid"], prefix("pyramids")),
      upload_bucket: get_secret(:meadow, ["buckets", "upload"], prefix("uploads")),
      preservation_check_bucket:
        get_secret(:meadow, ["buckets", "preservation_check"], prefix("preservation-checks")),
      streaming_bucket: get_secret(:meadow, ["buckets", "streaming"], prefix("streaming"))
    ]
  end
end
