defmodule Meadow.Metrics.Probes do
  @moduledoc """
  Gauges that have to be sampled rather than accumulated, run once per flush cycle.

  These are the measurements no event can produce, because what they measure is the
  *absence* of an event. A MediaConvert job that fails without emitting a state change,
  or an EventBridge delivery that goes missing, produces no `TranscodeComplete` and so
  never lands in the transcode duration histogram — the file set just sits there. Only a
  query can see that.
  """

  import Ecto.Query

  alias Meadow.Data.Schemas.ActionState
  alias Meadow.Pipeline.Actions.{CreateTranscodeJob, TranscodeComplete}
  alias Meadow.Repo
  alias Meadow.Metrics.Aggregator

  import Meadow.Utils.Atoms, only: [atom_to_string: 1]

  @default_stalled_after :timer.hours(1)

  @doc "Sample every probe and record the result on the aggregator."
  def run do
    report_while_nonzero("pipeline.transcode.stalled", stalled_transcodes())
    :ok
  end

  @doc """
  Report a count that is usually zero, without leaving a stale value behind.

  Gauges are republished on every flush until they are overwritten, so a probe that
  simply writes nothing when its count returns to zero pins the metric at its last
  non-zero value forever: the recovery never appears and an alarm on it never clears.
  Writing a zero every minute instead keeps a metric alive -- and billable -- for
  something that is almost always nothing.

  So the drop is published exactly once and the gauge is then retired. The three states
  are distinguishable from the gauge itself, with no bookkeeping of its own:

      value absent   -> already retired, nothing to say
      value is zero  -> the drop went out last flush, stop reporting
      value non-zero -> publish the drop, once
  """
  @spec report_while_nonzero(String.t(), number()) :: :ok
  def report_while_nonzero(name, count) when count != 0 do
    Aggregator.gauge(name, count)
  end

  def report_while_nonzero(name, _zero) do
    case Aggregator.gauge_value(name) do
      nil -> :ok
      previous when previous == 0 -> Aggregator.clear_gauge(name)
      _previous -> Aggregator.gauge(name, 0)
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

  defp stalled_after,
    do: Application.get_env(:meadow, :transcode_stalled_after, @default_stalled_after)
end
