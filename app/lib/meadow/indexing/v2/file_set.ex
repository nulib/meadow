defmodule Meadow.Indexing.V2.FileSet do
  @moduledoc """
  v2 encoding for FileSets
  """

  alias Meadow.Data.FileSets
  alias Meadow.AI.Provenance
  alias Meadow.Utils.ExtractedMetadata

  def encode(file_set) do
    %{
      accession_number: file_set.accession_number,
      ai_provenance: Provenance.target_summary_map("FileSet", file_set.id),
      alt_text: file_set.core_metadata.alt_text,
      annotations: encode_annotations(file_set),
      api_link: Path.join([api_url(), "file-sets", file_set.id]),
      api_model: "FileSet",
      collection: collection(file_set.work.collection),
      create_date: file_set.inserted_at,
      digests: file_set.core_metadata.digests,
      description: file_set.core_metadata.description,
      download_url: FileSets.download_uri_for(file_set),
      extracted_metadata: extracted_metadata(file_set.extracted_metadata),
      group_with: file_set.group_with,
      id: file_set.id,
      image_caption: file_set.core_metadata.image_caption,
      indexed_at: NaiveDateTime.utc_now(),
      label: file_set.core_metadata.label,
      mime_type: file_set.core_metadata.mime_type,
      modified_date: file_set.updated_at,
      poster_offset: file_set.poster_offset,
      published: file_set.work.published,
      rank: file_set.rank,
      representative_image_url: FileSets.representative_image_url_for(file_set),
      height: representative_dimension(file_set, :height),
      width: representative_dimension(file_set, :width),
      role: file_set.role.label,
      streaming_url: FileSets.distribution_streaming_uri_for(file_set),
      visibility: file_set.work.visibility.label,
      work_id: file_set.work_id,
      work_title: file_set.work.descriptive_metadata.title
    }
    |> Meadow.Utils.Map.nillify_empty()
  end

  defp representative_dimension(file_set, dimension) do
    dimensions_from_extracted_metadata(file_set.extracted_metadata)
    |> Map.get(dimension)
    |> case do
      value when is_number(value) -> value
      value when is_binary(value) -> String.to_integer(value)
      _ -> nil
    end
  end

  defp dimensions_from_extracted_metadata(%{"exif" => exif}) when is_map(exif) do
    exif
    |> Map.get("value", %{})
    |> case do
      %{"ImageWidth" => width, "ImageHeight" => height} -> %{width: width, height: height}
      _ -> %{}
    end
  end

  defp dimensions_from_extracted_metadata(%{"mediainfo" => mediainfo}) when is_map(mediainfo) do
    mediainfo
    |> get_in(["value", "media", "track"])
    |> then(&(&1 || []))
    |> Enum.find(&(Map.has_key?(&1, "Width") and Map.has_key?(&1, "Height")))
    |> case do
      %{"Width" => width, "Height" => height} -> %{width: width, height: height}
      _ -> %{}
    end
  end

  defp dimensions_from_extracted_metadata(_), do: %{}

  defp encode_annotations(file_set) do
    FileSets.list_annotations(file_set.id)
    |> Enum.filter(&(&1.status == "completed"))
    |> Enum.map(fn annotation ->
      %{
        id: annotation.id,
        type: annotation.type,
        language: annotation.language,
        model: annotation.model,
        content: annotation.content,
        ai_provenance: Provenance.target_summary_map("FileSetAnnotation", annotation.id)
      }
    end)
    |> case do
      [] -> nil
      annotations -> annotations
    end
  end

  def collection(%{id: id, title: title}), do: %{id: id, title: title}
  def collection(_), do: %{}

  def api_url, do: Application.get_env(:meadow, :dc_api) |> get_in([:v2, "base_url"])

  def extracted_metadata(%{"exif" => _} = value), do: ExtractedMetadata.transform(value)
  def extracted_metadata(%{"mediainfo" => _}), do: nil
  def extracted_metadata(value), do: value
end
