defmodule Meadow.Data.IndexWorkerTest do
  use Meadow.DataCase
  alias Meadow.Data.IndexWorker

  setup do
    worker = start_supervised!({IndexWorker, version: 2})
    on_exit(fn -> send(worker, :pause) end)
    %{worker: worker}
  end

  test "handle_info/2" do
    assert {:noreply, %{interval: 5678, version: 2}} ==
             IndexWorker.synchronize(%{interval: 5678, version: 2})
  end
end
