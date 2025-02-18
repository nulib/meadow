defmodule Meadow.Events.FileSets.StructuralMetadata do
  @moduledoc """
  Handles events related to structural metadata for file sets.
  """

  use Meadow.Utils.Logging

  alias Meadow.Config
  alias Meadow.Data.FileSets
  alias Meadow.Utils.AWS
  require Logger

  def write_structural_metadata(event) do
    case event do
      %{type: :delete, old_record: file_set} ->
        file_set |> if_structural_metadata(&do_delete_structural_metadata/1)

      %{new_record: file_set} ->
        file_set |> if_structural_metadata(&do_write_structural_metadata/1)
    end
  end

  defp if_structural_metadata(
         %{
           role: %{"id" => "A"},
           core_metadata: %{"mime_type" => mime_type}
         } = file_set,
         func
       ) do
    case mime_type do
      "audio/" <> _ -> func.(file_set)
      "video/" <> _ -> func.(file_set)
      _ -> :noop
    end
  end

  defp if_structural_metadata(_, _), do: :noop

  defp do_write_structural_metadata(%{
         id: id,
         structural_metadata: %{"type" => "webvtt", "value" => vtt}
       })
       when is_binary(vtt) do
    Logger.info("Writing structural metadata for #{id}")

    ExAws.S3.put_object(Config.pyramid_bucket(), FileSets.vtt_location(id), vtt,
      content_type: "text/vtt"
    )
    |> AWS.request()
  end

  defp do_write_structural_metadata(_), do: :noop

  defp do_delete_structural_metadata(%{id: id}) do
    Logger.info("Deleting structural metadata for #{id}")

    ExAws.S3.delete_object(Config.pyramid_bucket(), FileSets.vtt_location(id))
    |> AWS.request()
  end

  defp do_delete_structural_metadata(_), do: :noop
end
