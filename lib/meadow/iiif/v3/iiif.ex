defmodule Meadow.IIIF.V3 do
  @moduledoc """
  API for IIIF related functions
  """

  alias Meadow.Config
  alias Meadow.Data.Works
  alias Meadow.IIIF.V3.Generator
  alias Meadow.Utils.Pairtree

  def write_manifest(work_id) do
    work_id
    |> Works.get_work!()
    |> Generator.create_manifest()
    |> write_to_s3(Pairtree.manifest_v3_key(work_id))
  end

  @doc """
  Generate manifest id

  Examples:
    iex> manifest_id("37ad25ec-7eff-45d0-b759-eca65c9d560f")
    "http://localhost:9002/minio/test-pyramids/public/iiif3/37/ad/25/ec/-7/ef/f-/45/d0/-b/75/9-/ec/a6/5c/9d/56/0f-manifest.json"
  """
  def manifest_id(work_id) do
    Config.iiif_manifest_url() <> "iiif3/" <> Pairtree.manifest_path(work_id)
  end

  @doc """
  Generate image id

  Examples:
    iex> image_id("37ad25ec-7eff-45d0-b759-eca65c9d560f", "/full/600,/0/default.jpg")
    "http://localhost:8184/iiif/2/37ad25ec-7eff-45d0-b759-eca65c9d560f/full/600,/0/default.jpg"
  """
  def image_id(file_set_id, dimensions) do
    Config.iiif_server_url() <> file_set_id <> dimensions
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

  def image_service_id(file_set_id, prefix) do
    case file_set_id do
      nil ->
        nil

      id ->
        Config.iiif_server_url() <> prefix <> "/" <> id
    end
  end

  @doc """
  Generate annotation id

  Examples:
    iex> annotation_id("37ad25ec-7eff-45d0-b759-eca65c9d560f", "030ac101-58cc-4e1e-8a13-ad6d95a6adbe",1,2)
    "http://localhost:9002/minio/test-pyramids/public/iiif3/37/ad/25/ec/-7/ef/f-/45/d0/-b/75/9-/ec/a6/5c/9d/56/0f-manifest.json/canvas/030ac101-58cc-4e1e-8a13-ad6d95a6adbe/annotation_page/1/annotation/2"
  """
  def annotation_id(work_id, file_set_id, page_number, annotation_number) do
    "#{manifest_id(work_id)}/canvas/#{file_set_id}/annotation_page/#{page_number}/annotation/#{annotation_number}"
  end

  @doc """
  Generate annotation page id

  Examples:
    iex> annotation_page_id("37ad25ec-7eff-45d0-b759-eca65c9d560f", "030ac101-58cc-4e1e-8a13-ad6d95a6adbe",1)
    "http://localhost:9002/minio/test-pyramids/public/iiif3/37/ad/25/ec/-7/ef/f-/45/d0/-b/75/9-/ec/a6/5c/9d/56/0f-manifest.json/canvas/030ac101-58cc-4e1e-8a13-ad6d95a6adbe/annotation_page/1"
  """
  def annotation_page_id(work_id, file_set_id, page_number) do
    "#{manifest_id(work_id)}/canvas/#{file_set_id}/annotation_page/#{page_number}"
  end

  @doc """
  Generate canvas id

  Examples:
    iex> canvas_id("37ad25ec-7eff-45d0-b759-eca65c9d560f", "030ac101-58cc-4e1e-8a13-ad6d95a6adbe")
    "http://localhost:9002/minio/test-pyramids/public/iiif3/37/ad/25/ec/-7/ef/f-/45/d0/-b/75/9-/ec/a6/5c/9d/56/0f-manifest.json/canvas/030ac101-58cc-4e1e-8a13-ad6d95a6adbe"
  """
  def canvas_id(work_id, file_set_id) do
    "#{manifest_id(work_id)}/canvas/#{file_set_id}"
  end

  defp write_to_s3(manifest, key) do
    ExAws.S3.put_object(
      Meadow.Config.pyramid_bucket(),
      key,
      manifest,
      content_type: "application/json"
    )
    |> ExAws.request()
  end
end
