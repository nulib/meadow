defmodule Meadow.Pipeline.Actions.CreatePyramidTiff do
  @moduledoc "Create the pyramid tiff derivative for Image objects"

  alias Meadow.Config
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Repo
  alias Meadow.Utils.{AWS, Lambda}
  use Meadow.Pipeline.Actions.Common

  @timeout 240_000

  def actiondoc, do: "Create pyramid TIFF from source image"

  def already_complete?(file_set, _) do
    FileSets.pyramid_uri_for(file_set.id)
    |> Meadow.Utils.Stream.exists?()
  end

  def process(file_set, attributes) do
    source = file_set.core_metadata.location
    target = FileSets.pyramid_uri_for(file_set.id)

    case create_pyramid_tiff(source, target) do
      {:ok, dest} ->
        Repo.transaction(fn ->
          derivatives = FileSets.add_derivative(file_set, :pyramid_tiff, dest)
          FileSets.update_file_set(file_set, %{derivatives: derivatives})
          ActionStates.set_state!(file_set, __MODULE__, "ok")
        end)

        with %{context: "Version"} <- attributes do
          AWS.invalidate_cache(file_set, :pyramid)
        end

        :ok

      {:error, {:http_error, status, message}} ->
        Logger.warning("HTTP error #{status}: #{inspect(message)}. Retrying.")
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
