defmodule Meadow.ErrorTest do
  use Honeybadger.Case

  alias Meadow.Config

  setup do
    {:ok, _} = Honeybadger.API.start(self())

    on_exit(&Honeybadger.API.stop/0)
  end

  describe "report/3" do
    test "sends error notifications" do
      restart_with_config(exclude_envs: [])

      bad_function = fn denominator ->
        try do
          107 / denominator
        rescue
          exception -> Meadow.Error.report(exception, __MODULE__, __STACKTRACE__)
        end
      end

      bad_function.(0)
      assert_receive {:api_request, report}, 1000

      with request_context <- report |> get_in(["request", "context"]) do
        assert request_context |> Map.get("meadow_version") == Config.meadow_version()
        assert request_context |> Map.get("notifier") == __MODULE__ |> to_string()
      end
    end
  end
end
