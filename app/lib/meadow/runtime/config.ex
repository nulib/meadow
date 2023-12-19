defmodule Meadow.Runtime.Config do
  @moduledoc false

  import Config
  import Meadow.Runtime

  def configure! do
    config :meadow, Meadow.Repo,
      username: secret(:meadow, dig: [:db, :user], default: "docker"),
      password: secret(:meadow, dig: [:db, :password], default: "d0ck3r"),
      database: secret(:meadow, dig: [:db, :database], default: prefix("meadow")),
      hostname: secret(:meadow, dig: [:db, :host], default: "localhost"),
      port: secret(:meadow, dig: [:db, :port], default: 5432)

    config :meadow, Meadow.Search.Cluster,
      url: secret(:meadow, dig: [:search, :cluster_endpoint], default: "http://localhost:9200"),
      indexes: [
        %{
          name: prefix("dc-v2-work"),
          settings: priv_path("search/v2/settings/work.json"),
          version: 2,
          schemas: [Meadow.Data.Schemas.Work]
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
      ]

    config :meadow,
      environment_prefix: prefix(),
      mediaconvert_queue:
        secret(:meadow, dig: [:mediaconvert, :queue], default: prefix("transcode")),
      mediaconvert_role: secret(:meadow, dig: [:mediaconvert, :role_arn]),
      shared_links_index: prefix("shared_links"),
      ingest_bucket: secret(:meadow, dig: [:buckets, :ingest], default: prefix("ingest")),
      preservation_bucket:
        secret(:meadow, dig: [:buckets, :preservation], default: prefix("preservation")),
      pyramid_bucket: secret(:meadow, dig: [:buckets, :pyramid], default: prefix("pyramids")),
      upload_bucket: secret(:meadow, dig: [:buckets, :upload], default: prefix("uploads")),
      preservation_check_bucket:
        secret(:meadow,
          dig: [:buckets, :preservation_check],
          default: prefix("preservation-checks")
        ),
      streaming_bucket:
        secret(:meadow, dig: [:buckets, :streaming], default: prefix("streaming")),
      streaming_url:
        secret(:meadow,
          dig: [:streaming, :base_url],
          default: "https://#{prefix()}-streaming.s3.amazonaws.com/"
        ),
      multipart_upload_concurrency: System.get_env("MULTIPART_UPLOAD_CONCURRENCY", "10"),
      iiif_server_url:
        secret(:meadow,
          dig: [:iiif, :base_url],
          default: "https://iiif.dev.rdc.library.northwestern.edu/iiif/2/#{prefix()}"
        ),
      iiif_manifest_url_deprecated:
        secret(:meadow,
          dig: [:iiif, :manifest_url],
          default: "https://#{prefix()}-pyramids.s3.amazonaws.com/public/"
        ),
      iiif_distribution_id: secret(:meadow, dig: [:iiif, :distribution_id], default: nil),
      digital_collections_url:
        secret(:meadow,
          dig: [:dc, :base_url],
          default: "https://dc.rdc-staging.library.northwestern.edu/"
        ),
      progress_ping_interval: System.get_env("PROGRESS_PING_INTERVAL", "1000"),
      validation_ping_interval: System.get_env("VALIDATION_PING_INTERVAL", "1000"),
      pyramid_tiff_working_dir: System.tmp_dir!(),
      streaming_distribution_id:
        secret(:meadow, dig: [:streaming, :distribution_id], default: nil),
      work_archiver_endpoint: secret(:meadow, dig: [:work_archiver, :endpoint], default: "")

    # Configure Lambda-based actions
    config :meadow, :lambda,
      digester: configure_lambda(:digester, "digester"),
      exif: configure_lambda(:exif, "exif"),
      frame_extractor: configure_lambda(:frame_extractor, "frame-extractor"),
      mediainfo: configure_lambda(:mediainfo, "mediainfo"),
      mime_type: configure_lambda(:mime_type, "mime-type"),
      tiff: configure_lambda(:tiff, "pyramid-tiff")

    config :meadow, :livebook, url: environment("LIVEBOOK_URL", default: nil)

    config :meadow,
      dc_api: [
        v2: secret(:meadow, dig: [:dc_api, :v2])
      ]

    config :honeybadger,
      api_key: environment("HONEYBADGER_API_KEY", default: "DO_NOT_REPORT"),
      environment_name: System.get_env("HONEYBADGER_ENVIRONMENT", to_string(Mix.env())),
      revision: System.get_env("HONEYBADGER_REVISION", ""),
      repos: [Meadow.Repo],
      breadcrumbs_enabled: true,
      filter: Meadow.Error.Filter,
      exclude_envs: [:dev, :test]

    config :exldap, :settings,
      server: secret(:meadow, dig: [:ldap, :host], default: "localhost"),
      base: secret(:meadow, dig: [:ldap, :base], default: "DC=library,DC=northwestern,DC=edu"),
      port: secret(:meadow, dig: [:ldap, :port], cast: :integer, default: 390),
      user_dn:
        secret(:meadow,
          dig: [:ldap, :user_dn],
          default: "cn=Administrator,cn=Users,dc=library,dc=northwestern,dc=edu"
        ),
      password: secret(:meadow, dig: [:ldap, :password], default: "d0ck3rAdm1n!"),
      ssl: secret(:meadow, dig: [:ldap, :ssl], cast: :boolean, default: false)

    config :ueberauth, Ueberauth,
      providers: [
        nusso:
          {Ueberauth.Strategy.NuSSO,
           [
             base_url:
               secret(:meadow,
                 dig: [:nusso, :base_url],
                 default: "https://northwestern-prod.apigee.net/agentless-websso/"
               ),
             callback_path: "/auth/nusso/callback",
             consumer_key: secret(:meadow, dig: [:nusso, :api_key]),
             include_attributes: false
           ]}
      ]

    config :authoritex, geonames_username: secret(:meadow, dig: [:geonames, :username])
  end

  defp configure_lambda(lambda, function) do
    {:lambda, secret(:meadow, dig: [:pipeline, lambda], default: "#{function}:$LATEST")}
  end

  defp priv_path(path) do
    case :code.priv_dir(:meadow) do
      {:error, :bad_name} -> Path.join([".", "priv", path])
      priv_dir -> priv_dir |> to_string() |> Path.join(path)
    end
  end
end
