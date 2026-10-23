defmodule Meadow.Metrics.Probes do
  @moduledoc """
  Measurements that have to be sampled rather than accumulated.

  These are the things no event can report, because what they measure is the *absence*
  of an event. A MediaConvert job that fails without emitting a state change, or an
  EventBridge delivery that goes missing, produces no `TranscodeComplete` and so never
  lands in the transcode duration histogram -- the file set just sits there. Only a
  query can see that.

  `run/0` is called on a timer by `:telemetry_poller` (see `Meadow.Metrics`) and emits
  ordinary telemetry events, so the reporter treats a sampled value exactly like any
  other measurement.
  """

  import Ecto.Query

  alias Meadow.Data.Schemas.ActionState
  alias Meadow.Pipeline.Actions.{CreateTranscodeJob, TranscodeComplete}
  alias Meadow.Repo

  import Meadow.Utils.Atoms, only: [atom_to_string: 1]

  require Logger

  @stalled_event [:meadow, :pipeline, :transcode, :stalled]
  @default_stalled_after :timer.hours(1)

  @doc """
  Sample every probe and emit the results.

  Never raises: a probe that fails is logged and skipped, because this runs on a poller
  whose crash would take every probe down with it.
  """
  def run do
    report_while_nonzero(@stalled_event, stalled_transcodes())
    :ok
  rescue
    exception ->
      Logger.warning("Telemetry probe failed: #{Exception.message(exception)}")
      :ok
  end

  @doc """
  Emit a count that is usually zero, without leaving a stale value behind.

  The reporter clears its `last_value` cache on every push, so a value that stops being
  emitted stops being published -- which is what we want for a count that is almost
  always nothing. But it means a probe that simply goes quiet at zero never reports the
  *recovery*: the metric's last datapoint stays at whatever it was, and an alarm on it
  never clears.

  So the drop to zero is emitted exactly once and then the probe goes quiet. The
  previous value is kept in `:persistent_term`, which is built for values read often and
  written rarely -- once per push interval qualifies.
  """
  @spec report_while_nonzero(list(atom()), number()) :: :ok
  def report_while_nonzero(event, count) when count != 0 do
    emit(event, count)
  end

  def report_while_nonzero(event, _zero) do
    case previous(event) do
      0 -> :ok
      _ -> emit(event, 0)
    end
  end

  @doc """
  File sets whose transcode was started but never reported back.

  `CreateTranscodeJob` succeeded (so a job really was submitted), `TranscodeComplete` is
  still `waiting`, and enough time has passed that a legitimately slow transcode is an
  unlikely explanation.
  """
  @spec stalled_transcodes(non_neg_integer()) :: non_neg_integer()
  def stalled_transcodes(stalled_after \\ stalled_after()) do
    cutoff = DateTime.utc_now() |> DateTime.add(-stalled_after, :millisecond)

    from(started in ActionState,
      join: pending in ActionState,
      on: pending.object_id == started.object_id,
      where: started.action == ^atom_to_string(CreateTranscodeJob),
      where: started.outcome == "ok",
      where: started.updated_at < ^cutoff,
      where: pending.action == ^atom_to_string(TranscodeComplete),
      where: pending.outcome == "waiting",
      select: count(started.object_id)
    )
    |> Repo.one()
  end

  @doc """
  Milliseconds between pipeline kickoff for `file_set_id` and now.

  `Meadow.Pipeline.kickoff/2` initializes every action state for a file set in one
  transaction, so the earliest `inserted_at` across those rows is when the file set
  entered the pipeline. Returns `nil` when there are no action states to measure from.
  """
  @spec elapsed_since_kickoff(Ecto.UUID.t()) :: non_neg_integer() | nil
  def elapsed_since_kickoff(file_set_id) do
    from(a in ActionState, where: a.object_id == ^file_set_id, select: min(a.inserted_at))
    |> Repo.one()
    |> case do
      nil -> nil
      started_at -> DateTime.diff(DateTime.utc_now(), started_at, :millisecond)
    end
  end

  @doc "Forget what a probe last emitted. For tests."
  @spec reset(list(atom())) :: :ok
  def reset(event) do
    :persistent_term.erase({__MODULE__, event})
    :ok
  end

  defp emit(event, count) do
    :persistent_term.put({__MODULE__, event}, count)
    :telemetry.execute(event, %{count: count}, %{})
  end

  defp previous(event), do: :persistent_term.get({__MODULE__, event}, 0)

  defp stalled_after,
    do: Application.get_env(:meadow, :transcode_stalled_after, @default_stalled_after)
end
