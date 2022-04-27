defmodule Mix.Tasks.Sitemap.Generate do
  @moduledoc """
  Generate and upload Digital Collections sitemaps

  ## Command line options

    * `--ping` - ping Google and Bing to update after generating sitemaps (default: `false`)
  """
  use Mix.Task
  alias Meadow.Utils.Sitemap

  require Logger

  @shortdoc @moduledoc
  def run(args) do
    System.put_env("MEADOW_PROCESSES", "none")
    Mix.Task.run("app.start")

    %{ping: ping} =
      with {opts, _} <- OptionParser.parse!(args, strict: [ping: :boolean]) do
        opts |> Enum.into(%{ping: false})
      end

    Logger.configure(level: :info)
    Logger.info("Generating sitemaps")
    Sitemap.generate(ping)
  end
end
