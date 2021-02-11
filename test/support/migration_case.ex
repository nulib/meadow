defmodule Meadow.MigrationCase do
  use ExUnit.CaseTemplate

  @moduledoc """
  This module sets up test data for testing migrations.
  """

  alias Meadow.Config
  alias Meadow.Data.Collections

  import Meadow.TestHelpers

  @fixture_path "test/fixtures/migration"

  using do
    quote do
      use Meadow.DataCase
      use Meadow.S3Case
      use Meadow.AuthorityCase
    end
  end

  setup tags do
    Cachex.clear!(Meadow.Cache.ControlledTerms)
    sandbox_mode(tags)
    load_collections()

    sync("#{@fixture_path}/manifests", Config.migration_manifest_bucket())
    sync("#{@fixture_path}/binaries", Config.migration_binary_bucket())

    manifests =
      keys("#{@fixture_path}/manifests")
      |> Enum.map(&"s3://#{Config.migration_manifest_bucket()}/#{&1}")

    on_exit(fn ->
      clear("#{@fixture_path}/manifests", Config.migration_manifest_bucket())
      clear("#{@fixture_path}/binaries", Config.migration_binary_bucket())
      Cachex.clear!(Meadow.Cache.ControlledTerms)
    end)

    {:ok, %{authority_file: "#{@fixture_path}/terms.json", manifests: manifests}}
  end

  defp load_collections do
    File.read!("#{@fixture_path}/collections.json")
    |> Jason.decode!()
    |> Enum.each(&Collections.create_collection/1)
  end

  defp keys(source) do
    Path.wildcard(Path.join([source, "**", "*"]))
    |> Enum.filter(&File.regular?/1)
    |> Enum.map(fn path -> path |> Path.relative_to(source) end)
  end

  defp sync(source, bucket) do
    keys(source)
    |> Enum.each(fn key ->
      with file <- Path.join(source, key) do
        ExAws.S3.put_object(bucket, key, File.read!(file),
          metadata_directive: :REPLACE,
          meta: metadata(file)
        )
        |> ExAws.request!()
      end
    end)
  end

  defp clear(source, bucket) do
    keys(source)
    |> Enum.each(fn key ->
      ExAws.S3.delete_object(bucket, key)
      |> ExAws.request!()
    end)
  end

  defp metadata(file) do
    with metadata_file <- file <> ".metadata" do
      if File.exists?(metadata_file) do
        case File.read!(metadata_file) |> Jason.decode() do
          {:ok, metadata} -> metadata |> Enum.into([])
          _ -> []
        end
      else
        []
      end
    end
  end
end
