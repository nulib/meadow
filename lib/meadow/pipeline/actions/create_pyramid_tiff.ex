defmodule Meadow.Pipeline.Actions.CreatePyramidTiff do
  @moduledoc "Create the pyramid tiff derivative for Image objects"

  alias Meadow.Config
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Utils.Lambda
  alias Sequins.Pipeline.Action
  use Action
  use Meadow.Pipeline.Actions.Common

  @actiondoc "Create pyramid TIFF from source image"
  @timeout 240_000

  defp already_complete?(file_set, _) do
    FileSets.pyramid_uri_for(file_set.id)
    |> Meadow.Utils.Stream.exists?()
  end

  defp process(file_set, _, _) do
    source = file_set.metadata.location
    target = FileSets.pyramid_uri_for(file_set.id)

    case create_pyramid_tiff(source, target) do
      {:ok, _dest} ->
        ActionStates.set_state!(file_set, __MODULE__, "ok")
        :ok

      {:error, {:http_error, status, message}} ->
        Logger.warn("HTTP error #{status}: #{inspect(message)}. Retrying.")
        :retry

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
end
