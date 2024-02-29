defmodule Mix.Tasks.Sitemap.Generate do
  @moduledoc """
  Generate and upload Digital Collections sitemaps
  """
  use Mix.Task
  alias Meadow.Utils.Sitemap

  require Logger

  @shortdoc @moduledoc
  def run(_args) do
    System.put_env("MEADOW_PROCESSES", "none")
    Mix.Task.run("app.start")

    Logger.configure(level: :info)
    Logger.info("Generating sitemaps")
    Sitemap.generate()
  end
end
