defmodule Meadow.Pipeline.Actions.ExtractDominantColor do
  @moduledoc """
  Action to extract the dominant color from a pyramid tiff

  Subscribes to:
  * CreatePyramidTiff

  """
  alias Meadow.Config
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Utils.{Lambda, StructMap}
  alias Sequins.Pipeline.Action

  use Action
  use Meadow.Pipeline.Actions.Common

  require Logger

  @actiondoc "Extract dominant color from a pyramid tiff"
  @timeout 10_000

  defp already_complete?(file_set, _), do: false

  defp process(file_set, _attributes, _) do
    ActionStates.set_state!(file_set, __MODULE__, "started")

    file_set.core_metadata.location
    |> extract_dominant_color()
    |> handle_result(file_set)
  rescue
    err in RuntimeError -> {:error, err}
  end

  defp extract_dominant_color("s3://" <> _ = source) do
    Lambda.invoke(Config.lambda_config(:color), %{source: source}, @timeout)
  end

  defp extract_dominant_color(source) do
    Logger.error("Invalid location: #{source}")
    {:error, "Invalid location: #{source}"}
  end

  def handle_result({:ok, nil}, file_set) do
    ActionStates.set_state!(file_set, __MODULE__, "ok")
    :ok
  end

  def handle_result({:ok, color_data}, file_set) do
    FileSets.update_file_set(file_set, %{dominant_color: color_data})
    ActionStates.set_state!(file_set, __MODULE__, "ok")

    Logger.info(
      "Color data received from lambda for file set id #{file_set.id}: #{inspect(color_data)}"
    )

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
