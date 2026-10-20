defmodule Meadow.Metrics.ProbesTest do
  use Meadow.DataCase, shared: true

  alias Meadow.Data.ActionStates
  alias Meadow.Data.Schemas.{ActionState, FileSet}
  alias Meadow.Pipeline.Actions.{CreateTranscodeJob, FileSetComplete, TranscodeComplete}
  alias Meadow.Metrics.{Aggregator, Probes}

  import Meadow.Utils.Atoms, only: [atom_to_string: 1]

  setup do
    Aggregator.reset()
    on_exit(&Aggregator.reset/0)
    :ok
  end

  defp backdate(file_set_id, action, milliseconds) do
    when_ = DateTime.utc_now() |> DateTime.add(-milliseconds, :millisecond)

    from(a in ActionState,
      where: a.object_id == ^file_set_id and a.action == ^atom_to_string(action)
    )
    |> Repo.update_all(set: [inserted_at: when_, updated_at: when_])
  end

  defp transcode_in_progress(started_ago) do
    file_set_id = Ecto.UUID.generate()
    ActionStates.set_state!({FileSet, file_set_id}, CreateTranscodeJob, "ok")
    ActionStates.set_state!({FileSet, file_set_id}, TranscodeComplete, "waiting")
    backdate(file_set_id, CreateTranscodeJob, started_ago)
    file_set_id
  end

  describe "stalled_transcodes/1" do
    test "counts transcodes started long ago that never reported back" do
      transcode_in_progress(:timer.hours(3))
      assert Probes.stalled_transcodes(:timer.hours(1)) == 1
    end

    test "ignores transcodes that are merely slow" do
      transcode_in_progress(:timer.minutes(5))
      assert Probes.stalled_transcodes(:timer.hours(1)) == 0
    end

    test "ignores transcodes that completed" do
      file_set_id = transcode_in_progress(:timer.hours(3))
      ActionStates.set_state!({FileSet, file_set_id}, TranscodeComplete, "ok")

      assert Probes.stalled_transcodes(:timer.hours(1)) == 0
    end

    test "ignores transcodes that errored" do
      file_set_id = transcode_in_progress(:timer.hours(3))
      ActionStates.set_state!({FileSet, file_set_id}, TranscodeComplete, "error", "boom")

      assert Probes.stalled_transcodes(:timer.hours(1)) == 0
    end

    test "ignores file sets whose transcode was never successfully submitted" do
      file_set_id = Ecto.UUID.generate()
      ActionStates.set_state!({FileSet, file_set_id}, CreateTranscodeJob, "error", "boom")
      ActionStates.set_state!({FileSet, file_set_id}, TranscodeComplete, "waiting")
      backdate(file_set_id, CreateTranscodeJob, :timer.hours(3))

      assert Probes.stalled_transcodes(:timer.hours(1)) == 0
    end

    test "is zero when nothing is in flight" do
      assert Probes.stalled_transcodes(:timer.hours(1)) == 0
    end
  end

  describe "elapsed_since_kickoff/1" do
    test "measures from the earliest action state for the file set" do
      file_set_id = Ecto.UUID.generate()
      ActionStates.set_state!({FileSet, file_set_id}, CreateTranscodeJob, "ok")
      ActionStates.set_state!({FileSet, file_set_id}, FileSetComplete, "ok")
      backdate(file_set_id, CreateTranscodeJob, :timer.minutes(10))

      elapsed = Probes.elapsed_since_kickoff(file_set_id)

      assert elapsed >= :timer.minutes(10)
      assert elapsed < :timer.minutes(11)
    end

    test "is nil for a file set with no action states" do
      assert Probes.elapsed_since_kickoff(Ecto.UUID.generate()) == nil
    end
  end

  describe "run/0" do
    test "records the stalled transcode gauge" do
      transcode_in_progress(:timer.hours(3))
      Application.put_env(:meadow, :transcode_stalled_after, :timer.hours(1))
      on_exit(fn -> Application.delete_env(:meadow, :transcode_stalled_after) end)

      assert Probes.run() == :ok

      assert %{"Value" => 1} = reported("pipeline.transcode.stalled")
    end

    test "reports nothing when there has never been anything stalled" do
      assert Probes.run() == :ok

      refute reported("pipeline.transcode.stalled")
    end
  end

  describe "report_while_nonzero/2" do
    @gauge "probe.sparse"

    test "publishes a non-zero count" do
      Probes.report_while_nonzero(@gauge, 3)

      assert %{"Value" => 3} = reported(@gauge)
    end

    test "says nothing about a count that has always been zero" do
      Probes.report_while_nonzero(@gauge, 0)

      refute reported(@gauge)
    end

    test "publishes the drop to zero exactly once, then retires the gauge" do
      # Flush one: something is stalled.
      Probes.report_while_nonzero(@gauge, 2)
      assert %{"Value" => 2} = reported(@gauge)

      # Flush two: it recovered. The drop has to go out, or the metric stays pinned at 2
      # forever and an alarm on it never clears.
      Probes.report_while_nonzero(@gauge, 0)
      assert %{"Value" => 0} = reported(@gauge)

      # Flush three: still zero. Now it goes quiet rather than republishing zero every
      # minute for a metric that is almost always nothing.
      Probes.report_while_nonzero(@gauge, 0)
      refute reported(@gauge)

      # Flush four: still zero, and still quiet.
      Probes.report_while_nonzero(@gauge, 0)
      refute reported(@gauge)
    end

    test "comes back when the count goes non-zero again" do
      Probes.report_while_nonzero(@gauge, 2)
      Probes.report_while_nonzero(@gauge, 0)
      Probes.report_while_nonzero(@gauge, 0)
      refute reported(@gauge)

      Probes.report_while_nonzero(@gauge, 5)
      assert %{"Value" => 5} = reported(@gauge)
    end

    test "a sustained non-zero count keeps reporting" do
      for count <- [1, 2, 2, 3] do
        Probes.report_while_nonzero(@gauge, count)
      end

      assert %{"Value" => 3} = reported(@gauge)
    end
  end

  describe "running inside a real flush" do
    @counts_key {__MODULE__, :counts}

    setup do
      # The aggregator runs probes at the start of each flush and reads gauges after, so
      # a probe's value has to land in the same flush that produced it. Drive that with a
      # probe whose count changes between flushes.
      previous = Application.get_env(:meadow, :metrics_probes)

      Application.put_env(:meadow, :metrics_probes, [
        fn -> Probes.report_while_nonzero("flush.sparse", next_count()) end
      ])

      on_exit(fn ->
        :persistent_term.erase(@counts_key)

        case previous do
          nil -> Application.delete_env(:meadow, :metrics_probes)
          probes -> Application.put_env(:meadow, :metrics_probes, probes)
        end
      end)

      :ok
    end

    defp queue_counts(counts), do: :persistent_term.put(@counts_key, counts)

    defp next_count do
      case :persistent_term.get(@counts_key, []) do
        [count | rest] ->
          :persistent_term.put(@counts_key, rest)
          count

        [] ->
          0
      end
    end

    defp flushed(name) do
      Aggregator.flush().metric_data
      |> Enum.find(&(&1["MetricName"] == name))
    end

    test "a probe's value reaches the batch built by the same flush" do
      queue_counts([4])

      assert %{"Value" => 4, "Unit" => "Count"} = flushed("flush.sparse")
    end

    test "the drop to zero goes out once and then the gauge falls silent" do
      queue_counts([4, 0, 0, 0])

      assert %{"Value" => 4} = flushed("flush.sparse")
      assert %{"Value" => 0} = flushed("flush.sparse")
      refute flushed("flush.sparse")
      refute flushed("flush.sparse")
    end
  end

  defp reported(name), do: Enum.find(Aggregator.preview(), &(&1["MetricName"] == name))
end
