defmodule Mix.Tasks.Meadow.Buckets.Seed do
  @moduledoc """
  Add placeholder images to the pyramid bucket
  """
  use Mix.Task
  require Logger

  @prefix "00/00/00/00/-0/00/0-/00/00/-0/00/0-/00/00/00/00/00/"

  @shortdoc @moduledoc
  def run(_) do
    [:ex_aws, :hackney] |> Enum.each(&Application.ensure_all_started/1)

    Logger.info("Uploading placeholder images to the pyramid bucket")

    for file <- Path.wildcard("test/fixtures/placeholders/*.tif") do
      Meadow.Config.pyramid_bucket()
      |> ExAws.S3.put_object(
        @prefix <> Path.basename(file),
        File.read!(file)
      )
      |> ExAws.request!()
    end
  end
end
