defmodule Meadow.Pipeline.Actions.GenerateFileSetDigests do
  @moduledoc """
  Action to copy the digest map for a FileSet from the object tags

  Subscribes to:
  * Kicked off manually

  """
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Utils.StructMap

  use Meadow.Pipeline.Actions.Common

  require Logger

  def actiondoc, do: "Generate Digests for FileSet"

  def already_complete?(file_set, _) do
    case file_set
         |> StructMap.deep_struct_to_map()
         |> get_in([:core_metadata, :digests]) do
      %{"sha1" => _} -> true
      %{"sha256" => _} -> true
      %{"md5" => _} -> true
      %{sha1: _} -> true
      %{sha256: _} -> true
      %{md5: _} -> true
      _ -> false
    end
  end

  def process(file_set, _attributes) do
    ActionStates.set_state!(file_set, __MODULE__, "started")

    try do
      file_set.core_metadata.location
      |> copy_hashes_from_s3()
      |> handle_result(file_set)
    rescue
      Meadow.TimeoutError ->
        ActionStates.set_state!(file_set, __MODULE__, "pending")
        :retry

      e ->
        ActionStates.set_state!(file_set, __MODULE__, "error", Exception.message(e))
        {:error, Exception.message(e)}
    end
  end

  defp copy_hashes_from_s3(url) do
    %{host: bucket, path: "/" <> key} = URI.parse(url)

    ExAws.S3.get_object_tagging(bucket, key)
    |> ExAws.request!()
    |> get_in([:body, :tags])
    |> extract_tags()
    |> Enum.reject(&is_nil/1)
    |> Enum.into(%{})
  end

  defp extract_tags([]), do: []

  defp extract_tags([%{key: key, value: value} | tags]) do
    result =
      if key |> String.ends_with?("last-modified") do
        nil
      else
        case key do
          "computed-" <> algorithm ->
            {algorithm, value}

          _ ->
            nil
        end
      end

    [result | extract_tags(tags)]
  end

  def handle_result(hashes, _) when map_size(hashes) == 0, do: :ok

  def handle_result(hashes, file_set) do
    FileSets.update_file_set(file_set, %{core_metadata: %{digests: hashes}})
    ActionStates.set_state!(file_set, __MODULE__, "ok")
    :ok
  end
end
