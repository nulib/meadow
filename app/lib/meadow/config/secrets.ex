defmodule Meadow.Config.Secrets do
  @moduledoc """
  Functions for retrieving and loading configuration from AWS Secrets Manager and
  the local runtime environment
  """

  require Logger

  @config_map %{
    dcapi: "config/dcapi",
    ezid: "infrastructure/ezid",
    iiif: "infrastructure/iiif",
    index: "infrastructure/index",
    inference: "infrastructure/inference",
    ldap: "infrastructure/ldap",
    meadow: "config/meadow",
    nusso: "infrastructure/nusso",
    wildcard_ssl: "config/wildcard_ssl"
  }

  defp ensure_cache! do
    if :ets.info(:secret_cache, :name) == :undefined,
      do: :ets.new(:secret_cache, [:set, :protected, :named_table])
  end

  def clear_cache! do
    ensure_cache!()
    :ets.delete_all_objects(:secret_cache)
  end

  def get_secret(config, path, default \\ nil) do
    ensure_cache!()

    secrets =
      case :ets.lookup(:secret_cache, config) |> Keyword.get(config) do
        :missing ->
          nil

        nil ->
          case load_config(@config_map[config]) do
            nil ->
              :ets.insert(:secret_cache, {config, :missing})
              nil

            loaded ->
              :ets.insert(:secret_cache, {config, loaded})
              loaded
          end

        value ->
          value
      end

    case get_in(secrets, path) do
      nil -> default
      secret -> secret
    end
  end

  defp load_config(config_path) do
    System.get_env("SECRETS_PATH", nil) |> load_config(config_path)
  end

  defp load_config(nil, config_path), do: retrieve_config(config_path)

  defp load_config(prefix, config_path),
    do: Path.join(Enum.reject([prefix, config_path], &is_nil/1)) |> retrieve_config()

  defp retrieve_config(path) do
    Logger.debug("Retrieving AWS Secrets from #{path}")

    case ExAws.SecretsManager.get_secret_value(path) |> ExAws.request() do
      {:ok, %{"SecretString" => secret_string}} -> Jason.decode!(secret_string)
      {:error, _} -> nil
    end
  end

  def environment do
    if function_exported?(Mix, :env, 0), do: Mix.env(), else: :prod
  end

  def prefix do
    env =
      cond do
        System.get_env("RELEASE_NAME") -> nil
        function_exported?(Mix, :env, 0) -> Mix.env()
        true -> nil
      end

    [System.get_env("DEV_PREFIX"), env] |> Enum.reject(&is_nil/1) |> Enum.join("-")
  end

  def prefix(val), do: [prefix(), to_string(val)] |> reject_empty() |> Enum.join("-")
  #  defp atom_prefix(val), do: prefix(val) |> String.to_atom()
  defp reject_empty(list), do: Enum.reject(list, &(is_nil(&1) or &1 == ""))

  def environment_int(key, default) do
    case System.get_env(key) do
      nil -> default
      val -> String.to_integer(val)
    end
  end

  def project_root do
    if Code.loaded?(Mix),
      do: Path.dirname(Path.dirname(Mix.Project.build_path())),
      else: Path.dirname(:code.priv_dir(:meadow))
  end

  def priv_path(path) do
    case :code.priv_dir(:meadow) do
      {:error, :bad_name} -> Path.join([".", "priv", path])
      priv_dir -> priv_dir |> to_string() |> Path.join(path)
    end
  end
end