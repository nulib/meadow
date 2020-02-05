defmodule Meadow.Data.IndexWorkerTest do
  use Meadow.DataCase
  alias Meadow.Data.IndexWorker

  setup do
    worker = start_supervised!(IndexWorker)
    %{worker: worker}
  end

  test "handle_info/2" do
    assert {:noreply, 5678} == IndexWorker.handle_info(:synchronize, 5678)
  end
end
