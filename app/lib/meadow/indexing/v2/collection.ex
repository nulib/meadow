defmodule Meadow.Indexing.V2.Collection do
  @moduledoc """
  v2 encoding for Collections
  """

  def encode(collection) do
    %{
      admin_email: collection.admin_email,
      api_link: Path.join([api_url(), "collections", collection.id]),
      api_model: "Collection",
      create_date: collection.inserted_at,
      description: collection.description,
      featured: collection.featured,
      finding_aid_url: collection.finding_aid_url,
      id: collection.id,
      indexed_at: NaiveDateTime.utc_now(),
      keywords: collection.keywords,
      modified_date: collection.updated_at,
      published: collection.published,
      representative_image: representative_image(collection.representative_work),
      title: collection.title,
      visibility: encode_label(collection.visibility)
    }
  end

  def api_url, do: Application.get_env(:meadow, :dc_api) |> get_in([:v2, "base_url"])

  def representative_image(nil), do: %{}

  def representative_image(work) do
    %{
      work_id: work.id,
      url: work.representative_image
    }
  end

  def encode_label(%{label: label}), do: label
  def encode_label(_), do: nil
end
