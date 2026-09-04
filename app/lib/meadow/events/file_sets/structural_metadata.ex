defmodule Meadow.Events.FileSets.StructuralMetadata do
  @moduledoc """
  Handles events related to structural metadata for file sets: whenever a
  `file_set_structural_metadata` row is written with WebVTT content, the VTT
  file is published to the pyramid bucket.
  """

  alias Meadow.Config
  alias Meadow.AWS.S3
  alias Meadow.Data.FileSets

  use Meadow.Utils.Logging
  use WalEx.Event, name: Meadow

  require Logger

  on_event(:file_set_structural_metadata, %{}, [{__MODULE__, :write_structural_metadata}], & &1)

  def write_structural_metadata(%{type: type, new_record: record})
      when type in [:insert, :update],
      do: do_write_structural_metadata(record)

  def write_structural_metadata(_event), do: :noop

  defp do_write_structural_metadata(%{file_set_id: id, type: "webvtt", value: vtt})
       when is_binary(vtt) do
    Logger.info("Writing structural metadata for #{id}")

    S3.put_object(Config.pyramid_bucket(), FileSets.vtt_location(id), vtt,
      content_type: "text/vtt"
    )
  end

  defp do_write_structural_metadata(_), do: :noop
end
