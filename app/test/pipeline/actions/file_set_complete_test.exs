defmodule Meadow.Pipeline.Actions.FileSetCompleteTest do
  use Meadow.DataCase
  use Meadow.PipelineCase

  alias Meadow.Data.ActionStates
  alias Meadow.Pipeline.Actions.FileSetComplete
  alias Meadow.Metrics.Aggregator

  import ExUnit.CaptureLog

  test "process/2" do
    %{id: file_set_id} = file_set_fixture()

    assert {:ok, %{id: ^file_set_id}, %{}} =
             send_test_message(FileSetComplete, %{file_set_id: file_set_id}, %{})

    assert(ActionStates.ok?(file_set_id, FileSetComplete))

    assert capture_log(fn ->
             send_test_message(FileSetComplete, %{file_set_id: file_set_id}, %{})
           end) =~ "Skipping #{FileSetComplete} for #{file_set_id} - already complete"
  end

  describe "telemetry" do
    setup do
      Aggregator.reset()

      # FileSetComplete is deliberately off the production allowlist, so pin it on here:
      # these cases are about what the handler does with an action it is told to publish,
      # not about which actions the config happens to list.
      previous = Application.get_env(:meadow, :metrics, [])

      Application.put_env(
        :meadow,
        :metrics,
        Keyword.put(previous, :actions, ~w(FileSetComplete))
      )

      on_exit(fn ->
        Aggregator.reset()
        Application.put_env(:meadow, :metrics, previous)
      end)

      :ok
    end

    test "completing a file set records its end-to-end pipeline duration" do
      %{id: file_set_id} = file_set_fixture()

      # The end-to-end measurement is taken from the earliest action state for the file
      # set, so there has to be one to measure from.
      ActionStates.set_state!(
        %{id: file_set_id, __struct__: Meadow.Data.Schemas.FileSet},
        FileSetComplete,
        "waiting"
      )

      send_test_message(FileSetComplete, %{file_set_id: file_set_id}, %{})

      duration =
        Aggregator.preview()
        |> Enum.find(&(&1["MetricName"] == "pipeline.file_set.duration"))

      # Only reached when the stop event carries the file_set_id through from the span's
      # start metadata; without it the handler cannot look the file set up and this
      # metric silently never appears. Note this one does not depend on the allowlist --
      # the end-to-end measurement is emitted outside that check on purpose.
      assert duration, "expected an end-to-end duration for the completed file set"
      assert duration["Unit"] == "Milliseconds"
      assert Enum.sum(duration["Counts"]) == 1
    end

    test "the action metrics carry the action name rather than \"unknown\"" do
      %{id: file_set_id} = file_set_fixture()

      send_test_message(FileSetComplete, %{file_set_id: file_set_id}, %{})

      dimensions =
        Aggregator.preview()
        |> Enum.find(&(&1["MetricName"] == "pipeline.action.duration"))
        |> Map.fetch!("Dimensions")
        |> Enum.into(%{}, &{&1["Name"], &1["Value"]})

      assert dimensions == %{"Action" => "FileSetComplete"}
    end
  end
end
