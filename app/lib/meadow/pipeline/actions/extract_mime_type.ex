defmodule Meadow.Pipeline.Actions.ExtractMimeType do
  @moduledoc """
  Action to extract & store the mime type for a FileSet

  Subscribes to:
  * Kicked off manually

  """
  alias Meadow.Config
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Utils.{Lambda, MIME, StructMap}

  use Meadow.Pipeline.Actions.Common

  require Logger

  @error_message "error in mime-type extraction"

  def actiondoc, do: "Extract mime type from FileSet"

  def already_complete?(file_set, _) do
    file_set
    |> StructMap.deep_struct_to_map()
    |> get_in([:core_metadata, :mime_type])
    |> is_binary()
  end

  def process(file_set, _attributes) do
    ActionStates.set_state!(file_set, __MODULE__, "started")

    file_set.core_metadata.location
    |> extract_mime_type()
    |> handle_result(file_set)
  end

  defp extract_mime_type("s3://" <> _ = source) do
    Logger.info("Extracting mime type")
    %{host: bucket, path: "/" <> key} = URI.parse(source)

    case Lambda.invoke(
           Config.lambda_config(:mime_type),
           %{bucket: bucket, key: key, fallback: MIME.from_path(key)}
         ) do
      {:ok, %{"ext" => _, "mime" => mime_type}} ->
        {:ok, mime_type}

      {:ok, _other} ->
        {:error, "Unknown response from MIME extractor"}

      {:error, error} ->
        {:error, error}
    end
  end

  defp extract_mime_type(source) do
    Logger.error("Invalid location: #{source}")
    {:error, "Invalid location: #{source}"}
  end

  def handle_result({:ok, nil}, file_set) do
    ActionStates.set_state!(file_set, __MODULE__, "ok")
    :ok
  end

  def handle_result({:ok, mime_type}, file_set) do
    FileSets.update_file_set(file_set, %{core_metadata: %{mime_type: mime_type}})
    ActionStates.set_state!(file_set, __MODULE__, "ok")
    :ok
  end

  def handle_result({:error, {:http_error, status, message}}, _file_set) do
    Logger.warn("HTTP error #{status}: #{inspect(message)}. Retrying.")
    :retry
  end

  def handle_result({:error, _error}, file_set) do
    Logger.error(@error_message)
    ActionStates.set_state!(file_set, __MODULE__, "error", @error_message)
    {:error, @error_message}
  end
end
