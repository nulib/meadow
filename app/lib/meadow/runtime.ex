defmodule Meadow.Runtime do
  @moduledoc """
  Runtime configuration loader. Configuration priority (highest to lowest) and
  evaluation time is as follows:

  1. `config/{dev/test/prod}.local.exs` (runtime)
  5. `config/{dev/test/prod}.exs` (runtime)
  2. `Meadow.Runtime.Release.configure!/0` (runtime, release only)
  3. `Meadow.Runtime.{Dev/Test/Prod}.configure!/0` (runtime)
  4. `Meadow.Runtime.Config.configure!/0` (runtime)
  5. `config/{dev/test/prod}.exs` (compile-time)
  6. `config/config.exs` (compile-time)

  Note that the environment-specific files in the `config` directory get
  compiled but then also loaded at runtime.
  """

  alias Meadow.Utils.Truth
  require Logger

  @config_table :aws_secrets

  @doc """
  Load the runtime configuration
  """
  def configure! do
    load_configuration(Meadow.Runtime.Config)

    with env_atom <- env() |> to_string() |> String.capitalize() do
      Module.concat(__MODULE__, env_atom)
      |> load_configuration()
    end

    if release?() do
      load_configuration(Meadow.Runtime.Release)
    end

    load_configuration(Meadow.Runtime.Pipeline)
  end

  @doc """
  Load an environment secret

  opts:
    `cast: :boolean|:integer` - cast the return value to a boolean (truthy or false) or an integer
    `default: val` - return `val` if the value doesn't exist within the secret
    `to_file: "path/to/file"` - write the value to the given path and return the path
  """
  def environment(name, opts \\ []) do
    System.get_env(name)
    |> cast(opts[:cast])
    |> default(opts[:default])
    |> to_file(opts[:to_file])
  end

  @doc """
  Load a secret from AWS Secrets Manager

  opts:
    `dig: [key...]` - use `get_in` to retrieve a value from deep within the JSON secret
    `cast: :boolean|:integer` - cast the return value to a boolean (truthy or false) or an integer
    `default: val` - return `val` if the value doesn't exist within the secret
    `to_file: "path/to/file"` - write the value to the given path and return the path
  """
  def secret(config, opts \\ []) do
    ensure_ets_table(opts[:force_reload])

    case :ets.lookup(@config_table, config) do
      [{^config, secret}] -> secret
      [] -> fetch_aws_secrets(config)
    end
    |> dig(opts[:dig])
    |> cast(opts[:cast])
    |> default(opts[:default])
    |> to_file(opts[:to_file])
  end

  @doc """
  Return the default resource prefix based on the `DEV_PREFIX`
  environment variable and the Mix environment (e.g., `"mbk-dev"`)
  """
  def prefix do
    env_prefix = System.get_env("DEV_PREFIX")

    case env() do
      :release -> env_prefix
      env -> [env_prefix, env] |> Enum.reject(&is_nil/1) |> Enum.join("-")
    end
  end

  @doc """
  Return `val` prefixed by the default resource prefix
  """
  def prefix(val), do: [prefix(), to_string(val)] |> Enum.reject(&is_nil/1) |> Enum.join("-")

  @doc """
  Same as prefix/1 but returns an atom instead of a binary
  """
  def atom_prefix(val), do: prefix(val) |> String.to_atom()

  defp env, do: if(release?(), do: :release, else: Mix.env())
  defp release?, do: !function_exported?(Mix, :env, 0)

  defp cast(val, :boolean), do: Truth.to_bool(val)
  defp cast(nil, _), do: nil
  defp cast(val, nil), do: val

  defp cast(val, :integer) do
    cond do
      is_integer(val) -> val
      is_binary(val) -> String.to_integer(val)
      true -> to_string(val) |> String.to_integer()
    end
  end

  defp dig(nil, _), do: nil
  defp dig(val, nil), do: val
  defp dig(val, opt), do: get_in(val, opt)

  defp default(nil, opt), do: opt
  defp default(val, _), do: val

  defp to_file(val, nil), do: val

  defp to_file(val, path) do
    File.write!(path, val)
    path
  end

  defp ensure_ets_table(true) do
    :ets.delete(@config_table)
    ensure_ets_table(false)
  end

  defp ensure_ets_table(_) do
    if :ets.whereis(@config_table) == :undefined,
      do: :ets.new(@config_table, [:set, :private, :named_table])
  end

  defp fetch_aws_secrets(config) do
    [:hackney, :ex_aws] |> Enum.each(&Application.ensure_all_started/1)
    aws_secrets_path = System.get_env("SECRETS_PATH", "config")

    result =
      case Path.join(aws_secrets_path, to_string(config))
           |> ExAws.SecretsManager.get_secret_value()
           |> ExAws.request() do
        {:ok, %{"SecretString" => secret_string}} -> Jason.decode!(secret_string, keys: :atoms)
        {:error, _} -> %{}
      end

    :ets.insert(@config_table, {config, result})
    result
  end

  defp load_configuration(module) do
    case Code.ensure_loaded(module) do
      {:module, ^module} ->
        Logger.debug("Loading #{module}")
        module.configure!()

      {:error, _} ->
        Logger.debug("#{module} not found. Skipping.")
    end
  end
end
