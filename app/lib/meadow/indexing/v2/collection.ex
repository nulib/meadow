defmodule Meadow.Indexing.V2.Collection do
  @moduledoc """
  v2 encoding for Collections
  """

  def encode(collection) do
    %{
      admin_email: collection.admin_email,
      api_link: Path.join([api_url(), "collections", collection.id]),
      api_model: "Collection",
      canonical_link: Path.join([dc_url(), "collections", collection.id]),
      create_date: collection.inserted_at,
      description: collection.description,
      featured: collection.featured,
      finding_aid_url: collection.finding_aid_url,
      id: collection.id,
      indexed_at: NaiveDateTime.utc_now(),
      keywords: collection.keywords,
      modified_date: collection.updated_at,
      published: collection.published,
      representative_image: representative_image(collection),
      thumbnail: thumbnail_url(collection),
      title: collection.title,
      visibility: encode_label(collection.visibility)
    }
    |> Meadow.Utils.Map.nillify_empty()
  end

  def api_url, do: Application.get_env(:meadow, :dc_api) |> get_in([:v2, "base_url"])
  def dc_url, do: Application.get_env(:meadow, :digital_collections_url)

  def thumbnail_url(collection), do: "#{api_url()}/collections/#{collection.id}/thumbnail"

  def representative_image(collection) do
    %{
      work_id: collection.representative_work_id,
      url: collection.representative_image
    }
  end

  def encode_label(%{label: label}), do: label
  def encode_label(_), do: nil
end
