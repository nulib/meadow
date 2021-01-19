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

      hashes = generate_hashes(file_set.metadata.location)
      Logger.info("Hash for #{file_set.id}: #{hashes.sha256}")

      {:ok, _} =
        file_set
        |> FileSets.update_file_set(%{metadata: %{digests: hashes}})

      ActionStates.set_state!(file_set, __MODULE__, "ok")
      :ok
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

    case Lambda.invoke(Config.lambda_config(:digester), %{bucket: bucket, key: key}) do
      {:ok, result} -> %{sha256: result}
      {:error, error} -> raise error
    end
  end
end
