defmodule Mix.Tasks.Meadow.AiProvenance.Notes do
  @moduledoc """
  Report or migrate legacy AI disclosure notes into AI provenance records.
  """

  use Mix.Task

  alias Meadow.AI.Provenance.LegacyNotes

  @shortdoc "Report or migrate legacy AI disclosure notes"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        strict: [dry_run: :boolean, apply: :boolean],
        aliases: [d: :dry_run]
      )

    results =
      if opts[:apply] do
        LegacyNotes.apply()
      else
        LegacyNotes.dry_run()
      end

    Mix.shell().info(Jason.encode!(results, pretty: true))
  end
end
