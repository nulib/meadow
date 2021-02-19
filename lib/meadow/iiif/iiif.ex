defmodule Meadow.IIIF do
  @moduledoc """
  API for IIIF related functions
  """

  alias Meadow.Config
  alias Meadow.Data.Works
  alias Meadow.IIIF.Generator
  alias Meadow.Utils.Pairtree

  def write_manifest(work_id) do
    work_id
    |> Works.get_work!()
    |> Generator.create_manifest()
    |> write_to_s3(Pairtree.manifest_key(work_id))
  end

  @doc """
  Generate manifest id

  Examples:
    iex> manifest_id("37ad25ec-7eff-45d0-b759-eca65c9d560f")
    "http://localhost:9002/minio/test-pyramids/public/37/ad/25/ec/-7/ef/f-/45/d0/-b/75/9-/ec/a6/5c/9d/56/0f-manifest.json"
  """
  def manifest_id(work_id) do
    Config.iiif_manifest_url() <> Pairtree.manifest_path(work_id)
  end

  @doc """
  Generate image id

  Examples:
    iex> image_id("37ad25ec-7eff-45d0-b759-eca65c9d560f")
    "http://localhost:8184/iiif/2/37ad25ec-7eff-45d0-b759-eca65c9d560f/full/600,/0/default.jpg"
  """
  def image_id(file_set_id) do
    Config.iiif_server_url() <> file_set_id <> "/full/600,/0/default.jpg"
  end

  @doc """
  Generate image service id

  Examples:
    iex> image_service_id("37ad25ec-7eff-45d0-b759-eca65c9d560f")
    "http://localhost:8184/iiif/2/37ad25ec-7eff-45d0-b759-eca65c9d560f"
  """
  def image_service_id(file_set_id) do
    case file_set_id do
      nil ->
        nil

      id ->
        Config.iiif_server_url() <> id
    end
  end

  defp write_to_s3(manifest, key) do
    ExAws.S3.put_object(
      Meadow.Config.pyramid_bucket(),
      key,
      manifest
    )
    |> ExAws.request()
  end
end
