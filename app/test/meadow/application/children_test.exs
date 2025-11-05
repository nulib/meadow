defmodule Meadow.Application.ChildrenTest do
  use ExUnit.Case

  alias Meadow.Application.Children
  alias Meadow.Config

  describe "specs/0" do
    setup tags do
      with old_env <- Config.environment() do
        Application.put_env(:meadow, :environment, Map.get(tags, :environment, old_env))

        on_exit(fn ->
          Application.put_env(:meadow, :environment, old_env)
        end)
      end
    end

    @tag environment: :dev
    test "dev processes" do
      assert Children.specs() |> length() >= 11
    end

    @tag environment: :test
    test "test processes" do
      assert Children.specs() |> length() <= 11
    end

    @tag environment: :prod
    test "prod processes" do
      with specs <- Children.specs() do
        assert specs |> length() >= 10

        refute Enum.find(specs, fn
                 {_, args} when is_list(args) ->
                   args[:plug] == Meadow.Ark.MockServer

                 _ ->
                   false
               end)
      end
    end
  end

  test "processes/1" do
    ~w(aliases all basic pipeline web)
    |> Enum.each(fn group ->
      assert is_map(Children.processes(group))
    end)
  end
end
