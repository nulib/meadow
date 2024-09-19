# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

alias Meadow.Pipeline.Actions

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :meadow,
  ecto_repos: [Meadow.Repo]

config :meadow, Meadow.Repo,
  migration_primary_key: [
    name: :id,
    type: :binary_id,
    autogenerate: false,
    read_after_writes: true,
    default: {:fragment, "uuid_generate_v4()"}
  ],
  migration_timestamps: [type: :utc_datetime_usec],
  username: "docker",
  password: "d0ck3r",
  database: "meadow",
  hostname: "localhost",
  port: 5432

# Configures the endpoint
config :meadow, MeadowWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "C7BC/yBsTCe/PaJ9g0krwlQrNZZV2r3jSjeuGCeIu9mfNE+4bPcNPHiINQtIQk/B",
  render_errors: [view: MeadowWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: Meadow.PubSub,
  live_view: [signing_salt: "C7BC/yBsTCe/PaJ9g0krwlQrNZZV2r3jSjeuGCeIu9mfNE+4bPcNPHiINQtIQk/B"]

# Configures the Search cluster
config :meadow, Meadow.Search.Cluster,
  url: "http://localhost:9201",
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

config :meadow,
  pipeline_delay: :timer.seconds(5)

config :meadow,
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
  }

# Configure checksum requirements
config :meadow,
  required_checksum_tags: ["computed-md5"],
  checksum_wait_timeout: 3_600_000

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :lambda, :module, :id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :authoritex,
  authorities: [
    Authoritex.FAST.CorporateName,
    Authoritex.FAST.EventName,
    Authoritex.FAST.Form,
    Authoritex.FAST.Geographic,
    Authoritex.FAST.Personal,
    Authoritex.FAST.Topical,
    Authoritex.FAST.UniformTitle,
    Authoritex.FAST,
    Authoritex.GeoNames,
    Authoritex.Getty.AAT,
    Authoritex.Getty.TGN,
    Authoritex.Getty.ULAN,
    Authoritex.Getty,
    Authoritex.Homosaurus,
    Authoritex.LOC.GenreForms,
    Authoritex.LOC.Languages,
    Authoritex.LOC.Names,
    Authoritex.LOC.SubjectHeadings,
    NUL.Authority
  ]

config :ex_aws,
  access_key_id: [:instance_role],
  secret_access_key: [:instance_role],
  region: System.get_env("AWS_REGION", "us-east-1")

config :httpoison_retry, wait: 50

config :meadow, :extra_mime_types, %{
  "aif" => "audio/x-aiff",
  "aifc" => "audio/x-aiff",
  "aiff" => "audio/x-aiff",
  "flac" => "audio/x-flac",
  "framemd5" => "text/plain",
  "m4v" => "video/x-m4v",
  "md5" => "text/plain",
  "mkv" => "video/x-matroska",
  "mts" => "video/x-mts",
  "vob" => "video/x-vob",
  # package defaults to "text/xml"
  "xml" => "application/xml"
}

config :meadow, Meadow.Pipeline,
  actions: [
    Actions.IngestFileSet,
    Actions.ExtractMimeType,
    Actions.InitializeDispatch,
    Actions.GenerateFileSetDigests,
    Actions.ExtractExifMetadata,
    Actions.CopyFileToPreservation,
    Actions.CreateDerivativeCopy,
    Actions.CreatePyramidTiff,
    Actions.ExtractMediaMetadata,
    Actions.CreateTranscodeJob,
    Actions.TranscodeComplete,
    Actions.GeneratePosterImage,
    Actions.FileSetComplete
  ]

import_config("#{Mix.env()}.exs")
