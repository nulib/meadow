defmodule Meadow.Events.FileSets.StructuralMetadata do
  @moduledoc """
  Handles events related to structural metadata for file sets.
  """

  alias Meadow.Config
  alias Meadow.Data.FileSets
  alias Meadow.Utils.AWS

  use Meadow.Utils.Logging
  use WalEx.Event, name: Meadow

  require Logger

  on_event(:file_sets, %{}, [{__MODULE__, :write_structural_metadata}], & &1)

  def write_structural_metadata(event) do
    case event do
      %{new_record: file_set, changes: %{structural_metadata: _}} ->
        file_set |> do_write_structural_metadata()

      _ ->
        :noop
    end
  end

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
end
