defmodule Mix.Tasks.Meadow.ProcessesTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  test "mix meadow.processes" do
    with output <- capture_io(fn -> Mix.Task.run("meadow.processes") end) do
      assert output =~ ~r/Web processes:/
      assert output =~ ~r/Basic processes:/
      assert output =~ ~r/Pipeline processes:/
      assert output =~ ~r/Aliases:/
    end
  end
end
