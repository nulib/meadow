defmodule Meadow.Config do
  @moduledoc """
  Convenience methods for retrieving Meadow configuration
  """

  @doc "Retrieve the configured indexing interval"
  def index_interval do
    Application.get_env(:meadow, :index_interval, 120_000)
  end

  @doc "Retrieve the configured ingest bucket"
  def ingest_bucket do
    Application.get_env(:meadow, :ingest_bucket)
  end

  @doc "Retrieve the configured preservation bucket"
  def preservation_bucket do
    Application.get_env(:meadow, :preservation_bucket)
  end

  @doc "Retrieve the configured upload bucket"
  def upload_bucket do
    Application.get_env(:meadow, :upload_bucket)
  end

  @doc "Retrieve the configured pyramid bucket"
  def pyramid_bucket do
    Application.get_env(:meadow, :pyramid_bucket)
  end

  @doc "Retrieve the configured pyramid processor"
  def pyramid_processor do
    Application.get_env(
      :meadow,
      :pyramid_processor,
      priv_path("bin/fake_pyramid.js")
    )
  end

  @doc "Retrieve a list of configured buckets"
  def buckets do
    [
      ingest_bucket(),
      preservation_bucket(),
      upload_bucket(),
      pyramid_bucket()
    ]
  end

  @doc "Check whether Meadow is running in test mode"
  def test_mode? do
    Application.get_env(:meadow, :test_mode, false)
  end

  @doc "Locate a path relative to the priv directory"
  def priv_path(path) do
    :code.priv_dir(:meadow) |> to_string() |> Path.join(path)
  end
end
