if !function_exported?(:Env, :prefix, 0) do
  defmodule Env do
    @moduledoc """
    Configuration helpers for Meadow Dev, Staging, and Prod
    """
    alias Hush.Provider.{AwsSecretsManager, SystemEnvironment}

    def prefix do
      with env <- if(function_exported?(Mix, :env, 0), do: Mix.env(), else: nil) do
        [System.get_env("DEV_PREFIX"), env] |> Enum.reject(&is_nil/1) |> Enum.join("-")
      end
    end

    def prefix(val), do: [prefix(), to_string(val)] |> Enum.reject(&is_nil/1) |> Enum.join("-")
    def atom_prefix(val), do: prefix(val) |> String.to_atom()

    def aws_secret(name, opts \\ []),
      do: hush_secret(AwsSecretsManager, Path.join(secrets_path(), name), opts)

    def environment_secret(name, opts \\ []), do: hush_secret(SystemEnvironment, name, opts)
    def meadow_secret(opts \\ []), do: aws_secret("meadow", opts)

    defp hush_secret(provider, name, opts), do: {:hush, provider, name, opts}

    defp secrets_path, do: System.get_env("SECRETS_PATH", "config")
  end
end
