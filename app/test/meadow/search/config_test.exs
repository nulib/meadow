defmodule Meadow.Search.ConfigTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias Meadow.Data.Schemas.Work
  alias Meadow.Search.Config, as: SearchConfig

  describe "Meadow.Search.Config" do
    test "config_for/2" do
      logged =
        capture_log(fn ->
          config = SearchConfig.settings_for(Work, 2)
          refute config["default_pipeline"]
        end)

      assert logged
             |> String.contains?("No embedding model id found in config, skipping pipeline")
    end
  end
end
