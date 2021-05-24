defmodule Meadow.Pipeline.Actions.ExtractMediaMetadata do
  @moduledoc """
  Action to extract the media metadata from a FileSet

  """
  alias Meadow.Config
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Utils.{Lambda, StructMap}
  alias Sequins.Pipeline.Action

  use Action
  use Meadow.Pipeline.Actions.Common

  require Logger

  @actiondoc "Extract media metadata from FileSet"
  @timeout 120_000

  defp already_complete?(file_set, _) do
    with existing_metadata <-
           file_set
           |> StructMap.deep_struct_to_map()
           |> get_in([:metadata, :extracted_metadata, "mediainfo"]) do
      not (is_nil(existing_metadata) or Enum.empty?(existing_metadata))
    end
  end

  defp process(file_set, _attributes, _) do
    ActionStates.set_state!(file_set, __MODULE__, "started")

    file_set.metadata.location
    |> extract_media_metadata()
    |> handle_result(file_set)
  rescue
    err in RuntimeError -> {:error, err}
  end

  defp extract_media_metadata("s3://" <> _ = source) do
    Lambda.invoke(Config.lambda_config(:mediainfo), %{source: source}, @timeout)
  end

  defp extract_media_metadata(source) do
    Logger.error("Invalid location: #{source}")
    {:error, "Invalid location: #{source}"}
  end

  def handle_result({:ok, nil}, file_set) do
    ActionStates.set_state!(file_set, __MODULE__, "ok")
    :ok
  end

  def handle_result({:ok, metadata}, file_set) do
    extracted_metadata =
      case file_set.metadata.extracted_metadata do
        nil -> %{mediainfo: metadata}
        map -> Map.put(map, :mediainfo, metadata)
      end

    changes = %{metadata: %{extracted_metadata: extracted_metadata}}
    FileSets.update_file_set(file_set, changes)
    ActionStates.set_state!(file_set, __MODULE__, "ok")
    :ok
  end

  def handle_result({:error, {:http_error, status, message}}, _file_set) do
    Logger.warn("HTTP error #{status}: #{inspect(message)}. Retrying.")
    :retry
  end

  def handle_result({:error, error}, file_set) do
    ActionStates.set_state!(file_set, __MODULE__, "error", error)
    {:error, error}
  end
end
