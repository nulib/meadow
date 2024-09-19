# In this file, we load production configuration and
# secrets from environment variables. You can also
# hardcode secrets, although such is generally not
# recommended and you have to remember to add this
# file to your .gitignore.
import Config

config :logger, level: :info

config :meadow,
  environment: :prod,
  environment_prefix: nil
