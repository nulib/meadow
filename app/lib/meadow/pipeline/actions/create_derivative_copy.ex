defmodule Meadow.Pipeline.Actions.CreateDerivativeCopy do
  @moduledoc """
  Action to copy the file referenced in a FileSet
  to the pre-configured derivatives bucket.

  Subscribes to:
  *

  """
  alias Meadow.Data.{ActionStates, FileSets}
  alias Meadow.Repo
  use Meadow.Pipeline.Actions.Common
  alias Meadow.Utils.AWS
  require Logger
  import SweetXml, only: [sigil_x: 2]

  def actiondoc, do: "Create derivative copy of file set"

  def already_complete?(file_set, _) do
    file_set
    |> FileSets.derivative_location()
    |> Meadow.Utils.Stream.exists?()
  end

  def process(file_set, attributes) do
    ActionStates.set_state!(file_set, __MODULE__, "started")

    case create_derivative_copy(file_set, attributes) do
      {:ok, dest} ->
        Repo.transaction(fn ->
          derivatives = FileSets.add_derivative(file_set, :copy, dest)
          FileSets.update_file_set(file_set, %{derivatives: derivatives})
          ActionStates.set_state!(file_set, __MODULE__, "ok")
        end)

        :ok

      {:error, err} ->
        ActionStates.set_state!(file_set, __MODULE__, "error", err)
        {:error, err}
    end
  end

  defp create_derivative_copy(file_set, _attributes) do
    with dest_location <- FileSets.derivative_location(file_set) do
      copy_file(file_set, dest_location)
    end
  rescue
    err in ArgumentError ->
      Logger.error("Error creating derivative path: #{inspect(err)}")
      {:error, "Error creating derivative path: #{inspect(err)}"}
  end

  defp copy_file(file_set, dest_location) do
    with src_location <- file_set.core_metadata.location,
         %{host: src_bucket, path: "/" <> src_key} <- URI.parse(src_location),
         %{host: dest_bucket, path: "/" <> dest_key} <- URI.parse(dest_location),
         s3_metadata <- file_set.core_metadata.digests |> Enum.into([]) do
      Logger.info(
        "Making derivitive copy of source: #{src_location}, destination:  #{dest_location}"
      )

      content_type =
        case file_set.core_metadata.mime_type do
          nil -> "application/octet-stream"
          mime_type -> mime_type
        end

      tagging =
        file_set.core_metadata.digests
        |> Enum.map_join("&", fn {tag, value} -> ["computed-#{tag}", value] |> Enum.join("=") end)

      case AWS.copy_object(
             dest_bucket,
             dest_key,
             src_bucket,
             src_key,
             content_type: content_type,
             metadata_directive: :REPLACE,
             meta: s3_metadata,
             tagging: tagging,
             tagging_directive: :REPLACE
           ) do
        {:ok, _} -> {:ok, dest_location}
        {:error, {:http_error, _status, %{body: body}}} -> {:error, extract_error(body)}
        {:error, other} -> {:error, inspect(other)}
      end
    end
  end

  defp extract_error(body) do
    with error <-
           SweetXml.xmap(body, code: ~x"/Error/Code/text()", message: ~x"/Error/Message/text()") do
      "#{error[:code]}: #{error[:message]}"
    end
  end
end
