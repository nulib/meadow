defmodule Meadow.Pipeline.Actions.ExtractExifMetadata do
  @moduledoc """
  Action to extract the EXIF metadata from a FileSet

  Subscribes to:
  * Kicked off manually

  """
  alias Meadow.Config
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Utils.{Lambda, StructMap}
  alias Sequins.Pipeline.Action

  use Action
  use Meadow.Pipeline.Actions.Common

  require Logger

  @actiondoc "Extract EXIF metadata from FileSet"
  @timeout 10_000

  defp already_complete?(file_set, _) do
    with existing_exif <-
           file_set
           |> StructMap.deep_struct_to_map()
           |> get_in([:metadata, :exif]) do
      not (is_nil(existing_exif) or Enum.empty?(existing_exif))
    end
  end

  defp process(file_set, _attributes, _) do
    Logger.info("Beginning #{__MODULE__} for FileSet #{file_set.id}")
    ActionStates.set_state!(file_set, __MODULE__, "started")
    source = file_set.metadata.location

    case extract_exif_metadata(source) do
      {:ok, nil} ->
        ActionStates.set_state!(file_set, __MODULE__, "ok")
        :ok

      {:ok, exif_metadata} ->
        ActionStates.set_state!(file_set, __MODULE__, "ok")
        FileSets.update_file_set(file_set, %{metadata: %{exif: exif_metadata}})
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

  defp extract_exif_metadata("s3://" <> _ = source) do
    Lambda.invoke(Config.lambda_config(:exif), %{source: source}, @timeout)
  end

  defp extract_exif_metadata(source) do
    Logger.error("Invalid location: #{source}")
    {:error, "Invalid location: #{source}"}
  end
end
