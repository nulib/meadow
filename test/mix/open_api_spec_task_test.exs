defmodule Mix.Tasks.Meadow.OpenApiSpecTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias Mix.Tasks.Meadow.OpenApiSpec

  describe "OpenAPI Spec" do
    test "standard output" do
      task = fn -> OpenApiSpec.run([]) end
      assert is_map(Jason.decode!(capture_io(task)))
    end

    test "file output" do
      {:ok, outfile} = Briefly.create()
      OpenApiSpec.run([outfile])
      assert is_map(Jason.decode!(File.read!(outfile)))
    end
  end
end
