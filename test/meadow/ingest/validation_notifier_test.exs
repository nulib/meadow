defmodule Meadow.Ingest.ValidationNotifierTest do
  use ExUnit.Case
  alias Meadow.Ingest.ValidationNotifier

  setup do
    start_supervised!({ValidationNotifier, interval: 100})
    :ok
  end

  test "validation notifier running" do
    assert Process.whereis(Meadow.Ingest.ValidationNotifier) |> :sys.get_state() == %{
             interval: 100,
             status: :running
           }
  end
end
