defmodule Meadow.Data.IndexWorkerTest do
  use Meadow.DataCase
  alias Meadow.Data.IndexWorker

  setup do
    worker = start_supervised!({IndexWorker, version: 1})
    %{worker: worker}
  end

  test "handle_info/2" do
    assert {:noreply, %{interval: 5678, version: 1}} ==
             IndexWorker.synchronize(%{interval: 5678, version: 1})
  end
end
