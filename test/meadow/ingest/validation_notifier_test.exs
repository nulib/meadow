defmodule Meadow.Ingest.ValidationNotifierTest do
  use ExUnit.Case
  alias Meadow.Ingest.ValidationNotifier

  setup do
    start_supervised!({ValidationNotifier, interval: 100})
    :ok
  end

  test "validation notifier running" do
    assert %{
             interval: 100,
             status: :running
           } = Process.whereis(Meadow.Ingest.ValidationNotifier) |> :sys.get_state()
  end
end
