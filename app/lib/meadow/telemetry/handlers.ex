defmodule Meadow.Telemetry.Handlers do
  @moduledoc """
  Translates Meadow's pipeline telemetry events into aggregator measurements.

  Every clause here is wrapped in a rescue, because `:telemetry` permanently detaches any
  handler that raises. A single malformed event would otherwise take out all pipeline
  metrics until the next restart, with one log line to show for it.

  Absinthe events are deliberately not handled here. `Meadow.Telemetry.GraphQL` still
  re-emits them so they stay available to LiveDashboard, but nothing routes them to
  CloudWatch: dimensioning by field name across Meadow's schema would create a metric per
  root field, most of them near-empty.
  """

  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Pipeline.Actions.FileSetComplete
  alias Meadow.Metrics.{Aggregator, Probes}

  require Logger

  @handler_id "meadow-pipeline-metrics"

  @events [
    [:meadow, :pipeline, :action, :stop],
    [:meadow, :pipeline, :action, :exception],
    [:meadow, :pipeline, :action, :skip],
    [:meadow, :pipeline, :transcode, :complete],
    [:meadow, :pipeline, :file_set, :complete]
  ]

  @doc """
  Attach to the pipeline events.

  Detaches first so a supervisor restart re-attaches cleanly rather than failing on the
  duplicate handler id.
  """
  def attach do
    :telemetry.detach(@handler_id)
    :telemetry.attach_many(@handler_id, @events, &__MODULE__.handle_event/4, nil)
  end

  def detach, do: :telemetry.detach(@handler_id)

  @doc "The events this module handles."
  def events, do: @events

  def handle_event([:meadow, :pipeline, :action, :stop], measurements, metadata, _config) do
    action = action_name(metadata)

    if publish?(action) do
      duration = System.convert_time_unit(measurements.duration, :native, :millisecond)

      Aggregator.observe("pipeline.action.duration", duration, Action: action)

      Aggregator.count("pipeline.action.count", 1,
        Action: action,
        Outcome: metadata[:outcome] || "unknown"
      )
    end

    maybe_complete_file_set(metadata)
  rescue
    exception -> warn(:action_stop, exception)
  end

  # Skips never reach the action's own process/2, so there is no span and no duration to
  # record -- but a rising skip count is worth seeing, since it means work is arriving for
  # file sets that are already finished.
  def handle_event([:meadow, :pipeline, :action, :skip], _measurements, metadata, _config) do
    action = action_name(metadata)

    if publish?(action) do
      Aggregator.count("pipeline.action.count", 1,
        Action: action,
        Outcome: "skip"
      )
    end
  rescue
    exception -> warn(:action_skip, exception)
  end

  def handle_event([:meadow, :pipeline, :action, :exception], _measurements, metadata, _config) do
    action = action_name(metadata)

    if publish?(action) do
      Aggregator.count("pipeline.action.exception", 1,
        Action: action,
        Kind: metadata[:kind] || "error"
      )
    end
  rescue
    exception -> warn(:action_exception, exception)
  end

  def handle_event([:meadow, :pipeline, :transcode, :complete], measurements, metadata, _config) do
    media_type = media_type(metadata[:media_type])

    Aggregator.observe("pipeline.transcode.duration", measurements.duration_ms,
      MediaType: media_type
    )

    Aggregator.count("pipeline.transcode.count", 1,
      MediaType: media_type,
      Outcome: metadata[:outcome] || "unknown"
    )
  rescue
    exception -> warn(:transcode_complete, exception)
  end

  def handle_event([:meadow, :pipeline, :file_set, :complete], measurements, metadata, _config) do
    media_type = media_type(metadata[:media_type])

    Aggregator.observe("pipeline.file_set.duration", measurements.duration_ms,
      Role: metadata[:role] || "unknown",
      MediaType: media_type
    )
  rescue
    exception -> warn(:file_set_complete, exception)
  end

  def handle_event(_event, _measurements, _metadata, _config), do: :ok

  @media_types ~w(audio video image other)

  @doc """
  Classify a mime type into the handful of buckets worth dimensioning by.

  Full mime types would be unbounded as a dimension value; the top-level type is what
  actually explains a shift in action durations.

  Idempotent on purpose. `file_set_dimensions/1` and `TranscodeComplete` already classify
  before putting the value in metadata, so a handler that classifies again would be
  feeding `"video"` back in -- which matches no `"video/" <> _` clause and would fall
  through to `"other"`, quietly mislabelling every metric that carries a media type.
  """
  def media_type(nil), do: "other"
  def media_type("audio/" <> _), do: "audio"
  def media_type("video/" <> _), do: "video"
  def media_type("image/" <> _), do: "image"
  def media_type(bucket) when bucket in @media_types, do: bucket
  def media_type(_), do: "other"

  # When a file set finishes the pipeline, re-emit its end-to-end latency as its own
  # event. Measured from kickoff rather than from any single action, this is the only
  # metric that includes the queue wait between actions.
  defp maybe_complete_file_set(%{action: FileSetComplete, file_set_id: file_set_id} = metadata)
       when not is_nil(file_set_id) do
    case Probes.elapsed_since_kickoff(file_set_id) do
      nil ->
        :ok

      elapsed ->
        :telemetry.execute(
          [:meadow, :pipeline, :file_set, :complete],
          %{duration_ms: elapsed},
          Map.take(metadata, [:role, :media_type, :file_set_id])
        )
    end
  end

  defp maybe_complete_file_set(_metadata), do: :ok

  defp action_name(%{action: action}) when is_atom(action) and not is_nil(action),
    do: action |> Module.split() |> List.last()

  defp action_name(%{action: action}) when is_binary(action), do: action
  defp action_name(_), do: "unknown"

  defp warn(event, exception) do
    Logger.warning("Telemetry handler for #{event} failed: #{Exception.message(exception)}")
    :ok
  end

  defp publish?("unknown"), do: false

  defp publish?(action) do
    Application.get_env(:meadow, :metrics, [])
    |> Keyword.get(:actions, [])
    |> Enum.member?(action)
  end

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
end
