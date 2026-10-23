defmodule Meadow.Telemetry.Handlers do
  @moduledoc """
  Event transformations that have to happen before a metric can be derived.

  Most events need no handler at all: `TelemetryMetricsCloudwatch` and Live Dashboard
  both attach themselves to whatever `Meadow.Telemetry` declares. What is left here is
  the one case where the measurement does not exist in the event that triggers it, and
  the dimension helpers the pipeline uses when building span metadata.

  The handler is wrapped in a rescue because `:telemetry` permanently detaches any
  handler that raises. A single malformed event would otherwise take the end-to-end
  measurement out until the next restart, with one log line to show for it.
  """

  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Metrics.Probes
  alias Meadow.Pipeline.Actions.FileSetComplete

  require Logger

  @handler_id "meadow-pipeline-transforms"

  @events [[:meadow, :pipeline, :action, :stop]]

  @doc """
  Attach to the events that need transforming.

  Detaches first so a supervisor restart re-attaches cleanly rather than failing on the
  duplicate handler id.
  """
  def attach do
    :telemetry.detach(@handler_id)
    :telemetry.attach_many(@handler_id, @events, &__MODULE__.handle_event/4, nil)
  end

  def detach, do: :telemetry.detach(@handler_id)

  @doc "The events this module transforms."
  def events, do: @events

  @doc """
  Re-emit a completed file set's end-to-end pipeline latency as its own event.

  The action's own stop event says how long `FileSetComplete` took, which is not
  interesting. What is interesting is how long the file set spent in the pipeline, and
  that has to be looked up -- it is measured from kickoff, so it is the only measurement
  that includes the queue wait between actions.

  Emitted regardless of whether `FileSetComplete` is on the action allowlist, which it
  is not: the allowlist governs action timings, and this is not one.
  """
  def handle_event([:meadow, :pipeline, :action, :stop], _measurements, metadata, _config) do
    complete_file_set(metadata)
  rescue
    exception ->
      Logger.warning(
        "Telemetry transform for action_stop failed: #{Exception.message(exception)}"
      )

      :ok
  end

  def handle_event(_event, _measurements, _metadata, _config), do: :ok

  @media_types ~w(audio video image other)

  @doc """
  Classify a mime type into the handful of buckets worth dimensioning by.

  Full mime types would be unbounded as a dimension value; the top-level type is what
  actually explains a shift in action durations.

  Idempotent on purpose. `file_set_dimensions/1` and `TranscodeComplete` already classify
  before putting the value in metadata, so a caller that classifies again would be
  feeding `"video"` back in -- which matches no `"video/" <> _` clause and would fall
  through to `"other"`, quietly mislabelling every metric that carries a media type.
  """
  def media_type(nil), do: "other"
  def media_type("audio/" <> _), do: "audio"
  def media_type("video/" <> _), do: "video"
  def media_type("image/" <> _), do: "image"
  def media_type(bucket) when bucket in @media_types, do: bucket
  def media_type(_), do: "other"

  @doc """
  Dimension values describing a file set, for inclusion in span metadata.

  Kept here so the pipeline only has to hand telemetry a file set, without knowing which
  of its fields end up as dimensions.
  """
  def file_set_dimensions(%FileSet{} = file_set) do
    %{
      file_set_id: file_set.id,
      media_type: file_set.core_metadata && media_type(file_set.core_metadata.mime_type),
      role: file_set.role && file_set.role.id
    }
  end

  def file_set_dimensions(_), do: %{}

  defp complete_file_set(%{action: FileSetComplete, file_set_id: file_set_id} = metadata)
       when not is_nil(file_set_id) do
    case Probes.elapsed_since_kickoff(file_set_id) do
      nil ->
        :ok

      elapsed ->
        :telemetry.execute(
          [:meadow, :pipeline, :file_set, :complete],
          %{duration_ms: elapsed},
          %{
            role: metadata[:role] || "unknown",
            media_type: media_type(metadata[:media_type]),
            file_set_id: file_set_id
          }
        )
    end
  end

  defp complete_file_set(_metadata), do: :ok
end
