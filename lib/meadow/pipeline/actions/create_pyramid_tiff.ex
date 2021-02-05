defmodule Meadow.Pipeline.Actions.CreatePyramidTiff do
  @moduledoc "Create the pyramid tiff derivative for Image objects"

  alias Meadow.Config
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Utils.{Lambda, Pairtree}
  alias Sequins.Pipeline.Action
  use Action
  use Meadow.Pipeline.Actions.Common

  @timeout 600_000

  defp process(%{file_set_id: file_set_id}, _, _) do
    file_set = FileSets.get_file_set!(file_set_id)
    source = file_set.metadata.location
    target = pyramid_uri_for(file_set.id)

    case create_pyramid_tiff(source, target) do
      {:ok, _dest} ->
        ActionStates.set_state!(file_set, __MODULE__, "ok")
        :ok

      {:error, error} ->
        ActionStates.set_state!(file_set, __MODULE__, "error", error)
        {:error, error}
    end
  rescue
    err in RuntimeError -> {:error, err}
  end

  defp create_pyramid_tiff("s3://" <> _ = source, target) do
    Lambda.invoke(Config.lambda_config(:tiff), %{source: source, target: target}, @timeout)
  end

  defp create_pyramid_tiff(source, _target) do
    Logger.error("Invalid location: #{source}")
    {:error, "Invalid location: #{source}"}
  end

  defp pyramid_uri_for(file_set_id) do
    dest_bucket = Config.pyramid_bucket()

    dest_key = Path.join(["/", Pairtree.pyramid_path(file_set_id)])

    %URI{scheme: "s3", host: dest_bucket, path: dest_key} |> URI.to_string()
  end
end
