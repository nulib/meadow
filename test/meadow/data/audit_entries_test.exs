defmodule Meadow.Data.AuditEntriesTest do
  use Meadow.DataCase
  alias Meadow.Data.AuditEntries
  alias Meadow.Data.AuditEntries.AuditEntry
  import Assertions

  @actions [Test.Action.One, Test.Action.Two, "TestActionThree"]

  setup do
    file_set = file_set_fixture()
    AuditEntries.initialize_entries(file_set, @actions)
    {:ok, file_set: file_set}
  end

  test "initialize_entries", %{file_set: file_set} do
    with entries <- AuditEntries.get_entries(file_set.id) do
      entries
      |> Enum.map(fn entry -> {entry.action, entry.outcome} end)
      |> assert_lists_equal([
        {"Test.Action.One", "waiting"},
        {"Test.Action.Two", "waiting"},
        {"TestActionThree", "waiting"}
      ])
    end
  end

  test "add_entry", %{file_set: file_set} do
    {:ok, entry} = AuditEntries.add_entry(file_set, Test.Action.Two, "ok")
    assert entry.__struct__ == AuditEntry

    with entries <- AuditEntries.get_entries(file_set.id) do
      entries
      |> Enum.map(fn entry -> {entry.action, entry.outcome} end)
      |> assert_lists_equal([
        {"Test.Action.One", "waiting"},
        {"Test.Action.Two", "ok"},
        {"TestActionThree", "waiting"}
      ])
    end
  end

  test "add_entry!", %{file_set: file_set} do
    entry = AuditEntries.add_entry!(file_set, Test.Action.Two, "ok")
    assert entry.__struct__ == AuditEntry

    with entries <- AuditEntries.get_entries(file_set.id) do
      entries
      |> Enum.map(fn entry -> {entry.action, entry.outcome} end)
      |> assert_lists_equal([
        {"Test.Action.One", "waiting"},
        {"Test.Action.Two", "ok"},
        {"TestActionThree", "waiting"}
      ])
    end
  end

  test "latest_entry/1", %{file_set: file_set} do
    with entry <- AuditEntries.get_latest_entry(file_set.id) do
      assert entry.outcome == "waiting"
    end
  end

  test "latest_entry/2", %{file_set: file_set} do
    with entry <- AuditEntries.get_latest_entry(file_set.id, Test.Action.Two) do
      assert entry.outcome == "waiting"
      assert entry.action == "Test.Action.Two"
    end
  end

  test "latest_outcome/1", %{file_set: file_set} do
    assert AuditEntries.latest_outcome(file_set.id) == "waiting"
  end

  test "latest_outcome/2", %{file_set: file_set} do
    AuditEntries.add_entry!(file_set, Test.Action.Two, "ok")
    assert AuditEntries.latest_outcome(file_set.id, Test.Action.One) == "waiting"
    assert AuditEntries.latest_outcome(file_set.id, Test.Action.Two) == "ok"
  end

  test "ok?/1", %{file_set: file_set} do
    refute AuditEntries.ok?(file_set.id)
    AuditEntries.initialize_entries(file_set, @actions, "ok")
    assert AuditEntries.ok?(file_set.id)
  end

  test "ok?/2", %{file_set: file_set} do
    refute AuditEntries.ok?(file_set.id, Test.Action.Two)
    AuditEntries.add_entry!(file_set, Test.Action.Two, "ok")
    assert AuditEntries.ok?(file_set.id, Test.Action.Two)
  end

  test "error?/1", %{file_set: file_set} do
    refute AuditEntries.error?(file_set.id)
    AuditEntries.add_entry!(file_set, Test.Action.Two, "error")
    assert AuditEntries.error?(file_set.id)
  end

  test "error?/2", %{file_set: file_set} do
    refute AuditEntries.error?(file_set.id, Test.Action.Two)
    AuditEntries.add_entry!(file_set, Test.Action.Two, "error")
    assert AuditEntries.error?(file_set.id, Test.Action.Two)
  end

  test "get_entry!", %{file_set: file_set} do
    with %{id: id} <- AuditEntries.get_latest_entry(file_set.id) do
      assert entry = AuditEntries.get_entry!(id)
      assert entry.__struct__ == AuditEntry
    end
  end
end
