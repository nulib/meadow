defmodule Meadow.Runtime.Prod do
  @moduledoc false

  import Config

  def configure! do
    config :meadow, Meadow.Scheduler,
      overlap: false,
      timezone: "America/Chicago",
      jobs: [
        # Runs daily at 2AM Central Time
        {"0 2 * * *", {Meadow.Data.PreservationChecks, :start_job, []}}
      ]

    config :logger, level: :info
  end
end
