defmodule Meadow.Indexing.V1.Collection do
  @moduledoc """
  v1 encoding for Collections
  """

  def encode(collection) do
    %{
      adminEmail: collection.admin_email,
      createDate: collection.inserted_at,
      description: collection.description,
      featured: collection.featured,
      findingAidUrl: collection.finding_aid_url,
      id: collection.id,
      keywords: collection.keywords,
      model: %{application: "Meadow", name: "Collection"},
      modifiedDate: collection.updated_at,
      published: collection.published,
      representativeImage:
        case collection.representative_work do
          nil ->
            %{}

          work ->
            %{
              workId: work.id,
              url: work.representative_image
            }
        end,
      title: collection.title,
      visibility: format(collection.visibility),
      indexed_at: NaiveDateTime.utc_now()
    }
  end

  defp format(%{id: id, name: name}), do: %{id: id, name: name}
  defp format(%{id: id, title: title}), do: %{id: id, title: title}
  defp format(%{id: _id, label: _label, scheme: _scheme} = field), do: field
  defp format(_), do: %{}
end