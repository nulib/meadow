defmodule Meadow.Metrics.ProbesTest do
  use Meadow.DataCase, shared: true

  alias Meadow.Data.ActionStates
  alias Meadow.Data.Schemas.{ActionState, FileSet}
  alias Meadow.Metrics.Probes
  alias Meadow.Pipeline.Actions.{CreateTranscodeJob, FileSetComplete, TranscodeComplete}

  import Meadow.Utils.Atoms, only: [atom_to_string: 1]

  @stalled [:meadow, :pipeline, :transcode, :stalled]
  @probe [:test, :probe, :sparse]

  setup do
    owner = self()
    id = "probes-test-#{System.unique_integer([:positive])}"

    :telemetry.attach_many(
      id,
      [@stalled, @probe],
      fn event, measurements, _metadata, _ ->
        send(owner, {:telemetry, event, measurements})
      end,
      nil
    )

    Probes.reset(@stalled)
    Probes.reset(@probe)

    on_exit(fn ->
      :telemetry.detach(id)
      Probes.reset(@stalled)
      Probes.reset(@probe)
    end)

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

  describe "report_while_nonzero/2" do
    test "emits a non-zero count" do
      Probes.report_while_nonzero(@probe, 3)

      assert_received {:telemetry, @probe, %{count: 3}}
    end

    test "says nothing about a count that has always been zero" do
      Probes.report_while_nonzero(@probe, 0)

      refute_received {:telemetry, @probe, _}
    end

    test "emits the drop to zero exactly once, then goes quiet" do
      # The reporter clears its last_value cache on every push, so going quiet is how a
      # gauge stops being published -- but the recovery has to go out first, or the
      # metric's last datapoint stays non-zero and an alarm never clears.
      Probes.report_while_nonzero(@probe, 2)
      assert_received {:telemetry, @probe, %{count: 2}}

      Probes.report_while_nonzero(@probe, 0)
      assert_received {:telemetry, @probe, %{count: 0}}

      Probes.report_while_nonzero(@probe, 0)
      refute_received {:telemetry, @probe, _}

      Probes.report_while_nonzero(@probe, 0)
      refute_received {:telemetry, @probe, _}
    end

    test "comes back when the count goes non-zero again" do
      Probes.report_while_nonzero(@probe, 2)
      Probes.report_while_nonzero(@probe, 0)
      Probes.report_while_nonzero(@probe, 0)

      # Drain what the first two emitted.
      assert_received {:telemetry, @probe, %{count: 2}}
      assert_received {:telemetry, @probe, %{count: 0}}

      Probes.report_while_nonzero(@probe, 5)
      assert_received {:telemetry, @probe, %{count: 5}}
    end

    test "a sustained non-zero count keeps reporting" do
      for count <- [1, 2, 2, 3] do
        Probes.report_while_nonzero(@probe, count)
        assert_received {:telemetry, @probe, %{count: ^count}}
      end
    end
  end

  describe "run/0" do
    test "emits the stalled transcode count" do
      transcode_in_progress(:timer.hours(3))
      Application.put_env(:meadow, :transcode_stalled_after, :timer.hours(1))
      on_exit(fn -> Application.delete_env(:meadow, :transcode_stalled_after) end)

      assert Probes.run() == :ok
      assert_received {:telemetry, @stalled, %{count: 1}}
    end

    test "emits nothing when there has never been anything stalled" do
      assert Probes.run() == :ok
      refute_received {:telemetry, @stalled, _}
    end

    test "a failing probe is logged rather than crashing the poller" do
      # The poller calls run/0 on a timer; a raise here would take every probe with it.
      Application.put_env(:meadow, :transcode_stalled_after, :not_a_number)
      on_exit(fn -> Application.delete_env(:meadow, :transcode_stalled_after) end)

      assert Probes.run() == :ok
    end
  end
end
