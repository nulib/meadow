defmodule Meadow.Data.ActionStatesTest do
  use Meadow.DataCase
  alias Meadow.Data.ActionStates
  alias Meadow.Data.Schemas.ActionState
  import Assertions

  @actions [Test.Action.One, Test.Action.Two, "TestActionThree"]

  setup do
    file_set = file_set_fixture()
    ActionStates.initialize_states(file_set, @actions)
    {:ok, file_set: file_set}
  end

  test "initialize_states", %{file_set: file_set} do
    with states <- ActionStates.get_states(file_set.id) do
      states
      |> Enum.map(fn entry -> {entry.action, entry.outcome} end)
      |> assert_lists_equal([
        {"Test.Action.One", "waiting"},
        {"Test.Action.Two", "waiting"},
        {"TestActionThree", "waiting"}
      ])
    end
  end

  test "set_state", %{file_set: file_set} do
    {:ok, entry} = ActionStates.set_state(file_set, Test.Action.Two, "ok")
    assert entry.__struct__ == ActionState

    with states <- ActionStates.get_states(file_set.id) do
      states
      |> Enum.map(fn entry -> {entry.action, entry.outcome} end)
      |> assert_lists_equal([
        {"Test.Action.One", "waiting"},
        {"Test.Action.Two", "ok"},
        {"TestActionThree", "waiting"}
      ])
    end
  end

  test "set_state!", %{file_set: file_set} do
    entry = ActionStates.set_state!(file_set, Test.Action.Two, "ok")
    assert entry.__struct__ == ActionState

    with states <- ActionStates.get_states(file_set.id) do
      states
      |> Enum.map(fn entry -> {entry.action, entry.outcome} end)
      |> assert_lists_equal([
        {"Test.Action.One", "waiting"},
        {"Test.Action.Two", "ok"},
        {"TestActionThree", "waiting"}
      ])
    end
  end

  test "set_state! with error (string)", %{file_set: file_set} do
    with action_state <- ActionStates.set_state!(file_set, Test.Action.Two, "error", "reason") do
      assert action_state.outcome == "error"
      assert action_state.notes == "reason"
    end
  end

  test "set_state! with error (atom)", %{file_set: file_set} do
    with action_state <- ActionStates.set_state!(file_set, Test.Action.Two, "error", :reason) do
      assert action_state.outcome == "error"
      assert action_state.notes == "reason"
    end
  end

  test "set_state! with error (complex)", %{file_set: file_set} do
    with action_state <-
           ActionStates.set_state!(file_set, Test.Action.Two, "error", {:reason, "tuple", 27}) do
      assert action_state.outcome == "error"
      assert action_state.notes == ~s({:reason, "tuple", 27})
    end
  end

  test "latest_entry/1", %{file_set: file_set} do
    with entry <- ActionStates.get_latest_state(file_set.id) do
      assert entry.outcome == "waiting"
    end
  end

  test "latest_entry/2", %{file_set: file_set} do
    with entry <- ActionStates.get_latest_state(file_set.id, Test.Action.Two) do
      assert entry.outcome == "waiting"
      assert entry.action == "Test.Action.Two"
    end
  end

  test "latest_outcome/1", %{file_set: file_set} do
    assert ActionStates.latest_outcome(file_set.id) == "waiting"
  end

  test "latest_outcome/2", %{file_set: file_set} do
    ActionStates.set_state!(file_set, Test.Action.Two, "ok")
    assert ActionStates.latest_outcome(file_set.id, Test.Action.One) == "waiting"
    assert ActionStates.latest_outcome(file_set.id, Test.Action.Two) == "ok"
  end

  test "ok?/1", %{file_set: file_set} do
    refute ActionStates.ok?(file_set.id)
    ActionStates.initialize_states(file_set, @actions, "ok")
    assert ActionStates.ok?(file_set.id)
  end

  test "ok?/2", %{file_set: file_set} do
    refute ActionStates.ok?(file_set.id, Test.Action.Two)
    ActionStates.set_state!(file_set, Test.Action.Two, "ok")
    assert ActionStates.ok?(file_set.id, Test.Action.Two)
  end

  test "error?/1", %{file_set: file_set} do
    refute ActionStates.error?(file_set.id)
    ActionStates.set_state!(file_set, Test.Action.Two, "error")
    assert ActionStates.error?(file_set.id)
  end

  test "error?/2", %{file_set: file_set} do
    refute ActionStates.error?(file_set.id, Test.Action.Two)
    ActionStates.set_state!(file_set, Test.Action.Two, "error")
    assert ActionStates.error?(file_set.id, Test.Action.Two)
  end

  test "get_state!", %{file_set: file_set} do
    with %{id: id} <- ActionStates.get_latest_state(file_set.id) do
      assert entry = ActionStates.get_state!(id)
      assert entry.__struct__ == ActionState
    end
  end

  test "abort_remaining_waiting_actions/1", %{file_set: file_set} do
    ActionStates.set_state!(file_set, Test.Action.One, "ok")
    ActionStates.set_state!(file_set, Test.Action.Two, "error")
    ActionStates.abort_remaining_waiting_actions(file_set.id)

    with states <- ActionStates.get_states(file_set.id) do
      states
      |> Enum.map(fn entry -> {entry.action, entry.outcome} end)
      |> assert_lists_equal([
        {"Test.Action.One", "ok"},
        {"Test.Action.Two", "error"},
        {"TestActionThree", "error"}
      ])
    end
  end
end
