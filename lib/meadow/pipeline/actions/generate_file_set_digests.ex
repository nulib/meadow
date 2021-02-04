defmodule Meadow.Pipeline.Actions.GenerateFileSetDigests do
  @moduledoc """
  Action to generate the digest map for a FileSet

  Subscribes to:
  * Kicked off manually

  """
  alias Meadow.Config
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Utils.Lambda
  alias Sequins.Pipeline.Action

  use Action
  use Meadow.Pipeline.Actions.Common

  require Logger

  @actiondoc "Generate Digests for FileSet"

  defp process(%{file_set_id: file_set_id}, _attributes, _) do
    file_set = FileSets.get_file_set!(file_set_id)
    ActionStates.set_state!(file_set, __MODULE__, "started")

    try do
      Logger.info("Generating digests for #{file_set.id}")

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

    Lambda.invoke(Config.lambda_config(:digester), %{bucket: bucket, key: key})
  end
end
