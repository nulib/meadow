defmodule Meadow.Metrics.ConfirmationTest do
  @moduledoc """
  The interesting cases here are the ones where nobody answers.

  A confirmation prompt that can hang a boot is worse than the misconfiguration it
  guards against, so most of these assert that an unanswerable prompt downgrades the
  publisher and returns rather than waiting.
  """
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import Meadow.Metrics.Aggregator, only: [publisher: 0, set_publisher: 1]

  alias Meadow.Metrics.{CloudWatch, Confirmation, Logger}

  @confirm_env "MEADOW_CLOUDWATCH_CONFIRM"

  setup do
    previous_environment = Application.get_env(:meadow, :environment)
    System.delete_env(@confirm_env)

    on_exit(fn ->
      System.delete_env(@confirm_env)
      set_publisher(nil)
      Application.delete_env(:meadow, :environment_prefix)

      case previous_environment do
        nil -> Application.delete_env(:meadow, :environment)
        env -> Application.put_env(:meadow, :environment, env)
      end
    end)

    :ok
  end

  defp publishing_live_in(environment) do
    Application.put_env(:meadow, :environment, environment)
    set_publisher(CloudWatch)
  end

  describe "needs_confirmation?/0" do
    test "yes when publishing live outside production" do
      publishing_live_in(:dev)
      assert Confirmation.needs_confirmation?()
    end

    test "no in production, which is supposed to publish" do
      publishing_live_in(:prod)
      refute Confirmation.needs_confirmation?()
    end

    test "no in test, so the suite is never prompted" do
      publishing_live_in(:test)
      refute Confirmation.needs_confirmation?()
    end

    test "no when the publisher only logs" do
      Application.put_env(:meadow, :environment, :dev)
      set_publisher(Logger)

      refute Confirmation.needs_confirmation?()
    end

    test "no when nothing publishes at all" do
      Application.put_env(:meadow, :environment, :dev)
      set_publisher(nil)

      refute Confirmation.needs_confirmation?()
    end
  end

  describe "confirm!/1 when there is nothing to confirm" do
    test "leaves production alone without prompting" do
      publishing_live_in(:prod)

      assert Confirmation.confirm!() == :ok
      assert publisher() == CloudWatch
    end

    test "leaves a logging publisher alone" do
      Application.put_env(:meadow, :environment, :dev)
      set_publisher(Logger)

      assert Confirmation.confirm!() == :ok
      assert publisher() == Logger
    end
  end

  describe "confirm!/1 with #{@confirm_env} set" do
    test "skips the prompt entirely" do
      publishing_live_in(:dev)
      System.put_env(@confirm_env, "yes")

      log =
        capture_log(fn -> assert Confirmation.confirm!() == :ok end)

      assert publisher() == CloudWatch
      assert log =~ @confirm_env
    end

    test "a value that is not affirmative does not count as confirmation" do
      publishing_live_in(:dev)
      System.put_env(@confirm_env, "maybe")

      capture_log(fn -> Confirmation.confirm!() end)

      assert publisher() |> is_nil()
    end
  end
end
