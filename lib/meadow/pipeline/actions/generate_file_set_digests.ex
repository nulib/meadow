defmodule Meadow.Pipeline.Actions.GenerateFileSetDigests do
  @moduledoc """
  Action to generate the digest map for a FileSet

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

  @actiondoc "Generate Digests for FileSet"
  @timeout 240_000

  defp already_complete?(file_set, _) do
    case file_set
         |> StructMap.deep_struct_to_map()
         |> get_in([:metadata, :digests]) do
      %{"sha1" => _, "sha256" => _} -> true
      %{sha1: _, sha256: _} -> true
      _ -> false
    end
  end

  defp process(file_set, _attributes, _) do
    ActionStates.set_state!(file_set, __MODULE__, "started")

    try do
      case generate_hashes(file_set.metadata.location) do
        {:ok,
         %{"sha256" => <<sha256::binary-size(64)>>, "sha1" => <<_sha1::binary-size(40)>>} = hashes} ->
          Logger.info("Hash for #{file_set.id}: #{sha256}")
          {:ok, _} = FileSets.update_file_set(file_set, %{metadata: %{digests: hashes}})
          ActionStates.set_state!(file_set, __MODULE__, "ok")
          :ok

        {:ok, unexpected_result} ->
          ActionStates.set_state!(file_set, __MODULE__, "error", unexpected_result)
          {:error, unexpected_result}

        {:error, {:http_error, status, message}} ->
          Logger.warn("HTTP error #{status}: #{inspect(message)}. Retrying.")
          :retry

        {:error, error} ->
          raise error
      end
    rescue
      Meadow.Utils.Stream.Timeout ->
        ActionStates.set_state!(file_set, __MODULE__, "pending")
        :retry

      e ->
        ActionStates.set_state!(file_set, __MODULE__, "error", Exception.message(e))
        {:error, Exception.message(e)}
    end
  end

  def generate_hashes(url) do
    %{host: bucket, path: "/" <> key} = URI.parse(url)

    Lambda.invoke(Config.lambda_config(:digester), %{bucket: bucket, key: key}, @timeout)
  end
end
