defmodule Meadow.Pipeline.Actions.ExtractExifMetadata do
  @moduledoc """
  Action to extract the EXIF metadata from a FileSet

  Subscribes to:
  * Kicked off manually

  """
  alias Meadow.Config
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Utils.Lambda

  use Meadow.Pipeline.Actions.Common

  require Logger

  @timeout 120_000

  def actiondoc, do: "Extract EXIF metadata from FileSet"

  def already_complete?(file_set, _) do
    case FileSets.extracted_tool(file_set, "exif") do
      nil -> false
      %{entries: entries} -> not Enum.empty?(entries)
    end
  end

  def process(file_set, _attributes) do
    ActionStates.set_state!(file_set, __MODULE__, "started")

    file_set.core_metadata.location
    |> extract_exif_metadata()
    |> handle_result(file_set)
  rescue
    err in RuntimeError -> {:error, err}
  end

  defp extract_exif_metadata("s3://" <> _ = source) do
    Lambda.invoke(Config.lambda_config(:exif), %{source: source}, timeout: @timeout)
  end

  defp extract_exif_metadata(source) do
    Logger.error("Invalid location: #{source}")
    {:error, "Invalid location: #{source}"}
  end

  def handle_result({:ok, nil}, file_set) do
    ActionStates.set_state!(file_set, __MODULE__, "ok")
    :ok
  end

  def handle_result({:ok, exif_metadata}, file_set) do
    extracted_metadata =
      file_set |> FileSets.extracted_metadata_map() |> Map.put("exif", exif_metadata)

    FileSets.update_file_set(file_set, %{extracted_metadata: extracted_metadata})
    ActionStates.set_state!(file_set, __MODULE__, "ok")
    :ok
  end

  def handle_result({:error, {:http_error, status, message}}, _file_set) do
    Logger.warning("HTTP error #{status}: #{inspect(message)}. Retrying.")
    :retry
  end

  def handle_result({:error, error}, file_set) do
    ActionStates.set_state!(file_set, __MODULE__, "error", error)
    {:error, error}
  end
end
