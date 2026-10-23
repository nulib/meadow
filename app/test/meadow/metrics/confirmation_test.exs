defmodule Meadow.Metrics.ConfirmationTest do
  use ExUnit.Case, async: false

  alias Meadow.Metrics.Confirmation

  @confirm_env Confirmation.confirm_env()

  setup do
    previous = Application.get_env(:meadow, :environment)
    System.delete_env(@confirm_env)

    on_exit(fn ->
      System.delete_env(@confirm_env)

      case previous do
        nil -> Application.delete_env(:meadow, :environment)
        env -> Application.put_env(:meadow, :environment, env)
      end
    end)

    :ok
  end

  defp in_environment(env), do: Application.put_env(:meadow, :environment, env)

  describe "needs_confirmation?/0" do
    test "production is meant to publish" do
      in_environment(:prod)
      refute Confirmation.needs_confirmation?()
    end

    test "test never publishes, so there is nothing to confirm" do
      in_environment(:test)
      refute Confirmation.needs_confirmation?()
    end

    test "anything else has to be confirmed" do
      in_environment(:dev)
      assert Confirmation.needs_confirmation?()
    end
  end

  describe "live?/0" do
    test "production publishes without asking" do
      in_environment(:prod)
      assert Confirmation.live?()
    end

    test "a dev box does not publish by default" do
      in_environment(:dev)
      refute Confirmation.live?()
    end

    test "a dev box publishes once confirmed" do
      in_environment(:dev)

      for value <- ~w(yes true 1 YES True) do
        System.put_env(@confirm_env, value)
        assert Confirmation.live?(), "#{inspect(value)} should confirm"
      end
    end

    test "a value that is not affirmative does not confirm" do
      in_environment(:dev)

      for value <- ["", "no", "maybe", "0", "false"] do
        System.put_env(@confirm_env, value)
        refute Confirmation.live?(), "#{inspect(value)} should not confirm"
      end
    end

    test "surrounding whitespace and case are ignored" do
      in_environment(:dev)
      System.put_env(@confirm_env, "  Yes  ")

      assert Confirmation.live?()
    end
  end

  describe "reason/0" do
    test "names the environment when no confirmation is needed" do
      in_environment(:prod)
      assert Confirmation.reason() =~ "prod"
    end

    test "names the variable when it is what decided" do
      in_environment(:dev)
      assert Confirmation.reason() =~ "#{@confirm_env} is not set"

      System.put_env(@confirm_env, "yes")
      assert Confirmation.reason() =~ "#{@confirm_env} is set"
    end
  end
end
