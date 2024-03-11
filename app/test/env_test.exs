defmodule EnvTest do
  use ExUnit.Case

  import Env

  setup %{environment: environment} do
    set_env = fn
      {key, nil} -> System.delete_env(key)
      {key, value} -> System.put_env(key, value)
    end

    saved = Enum.map(environment, fn {key, _} -> {key, System.get_env(key)} end)
    Enum.each(environment, set_env)
    on_exit(fn -> Enum.each(saved, set_env) end)
  end

  describe "hush" do
    @describetag environment: [{"SECRETS_PATH", "foo/config"}]

    test "aws_secret/2" do
      assert aws_secret("meadow", test: :value) ==
               {:hush, Hush.Provider.AwsSecretsManager, "foo/config/meadow", [test: :value]}
    end

    test "meadow_secret/2" do
      assert meadow_secret(test: :value) ==
               {:hush, Hush.Provider.AwsSecretsManager, "foo/config/meadow", [test: :value]}
    end

    test "environment_secret/2" do
      assert environment_secret("DEV_PREFIX", test: :value) ==
               {:hush, Hush.Provider.SystemEnvironment, "DEV_PREFIX", [test: :value]}
    end
  end

  describe "dev environment" do
    @describetag environment: [{"DEV_PREFIX", "env"}]

    test "prefix/0" do
      assert prefix() == "env-test"
    end

    test "prefix/1" do
      assert prefix("database") == "env-test-database"
    end

    test "atom_prefix/1" do
      assert atom_prefix("database") == :"env-test-database"
    end
  end

  describe "release environment" do
    @describetag environment: [{"DEV_PREFIX", nil}, {"RELEASE_NAME", "meadow"}]

    test "prefix/0" do
      assert prefix() == ""
    end

    test "prefix/1" do
      assert prefix("database") == "database"
    end

    test "atom_prefix/1" do
      assert atom_prefix("database") == :database
    end
  end
end
