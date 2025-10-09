# Meadow configuration takes place across multiple files.
#
# Compile-time configs are evaluated when Meadow is compiled, with
# higher priority given to files farther down the list (i.e., environment-
# specific configs take precedence over global config).
#
#   config/config.exs
#   config/[environment].exs
#
# Runtime configs work the same way, except they are set at runtime.
# This means they can read configuration data that may not be available
# at compile-time, or that may change. This includes files on disk,
# the runtime system environment, or remote datastores such as AWS
# Secrets Manager.
#
#   lib/meadow/config/runtime.ex
#   lib/meadow/config/runtime/[environment].ex
#   config/[environment].local.exs
#
# When one configuration takes precedence over other, keyword lists are
# deep merged, while other values (e.g., maps) are overwritten.
#
# It is _strongly_ suggested that component configurations be done entirely
# at compile-time _or_ runtime and not some of each, e.g.:
# don't try to
# ```
# config :meadow, :component, [static properties]
# ```
# at compile time and
# ```
# config :meadow, :component, [dynamic properties]
# ```
# at runtime.

# General application configuration
import Config

alias Meadow.Pipeline.Actions

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :lambda, :module, :id]

config :meadow,
  ecto_repos: [Meadow.Repo]

# Use Jason for JSON parsing in Phoenix
config :phoenix, json_library: Jason, serve_endpoints: true

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

config :httpoison_retry, wait: 50

config :ex_aws,
  http_client: Meadow.Utils.AWS.HttpClient,
  hackney_opts: [
    pool: :default,
    max_connections: 500,
    checkout_timeout: 30_000
  ]

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

config :ueberauth, Ueberauth, providers: [nusso: {Ueberauth.Strategy.NuSSO, []}]

import_config("#{Mix.env()}.exs")
