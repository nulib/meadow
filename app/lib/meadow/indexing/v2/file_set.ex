defmodule Meadow.Indexing.V2.FileSet do
  @moduledoc """
  v2 encoding for FileSets
  """

  alias Meadow.Data.FileSets
  alias Meadow.Utils.ExtractedMetadata

  def encode(file_set) do
    %{
      accession_number: file_set.accession_number,
      api_link: Path.join([api_url(), "file-sets", file_set.id]),
      api_model: "FileSet",
      create_date: file_set.inserted_at,
      digests: file_set.core_metadata.digests,
      description: file_set.core_metadata.description,
      extracted_metadata: extracted_metadata(file_set.extracted_metadata),
      id: file_set.id,
      indexed_at: NaiveDateTime.utc_now(),
      label: file_set.core_metadata.label,
      modified_date: file_set.updated_at,
      poster_offset: file_set.poster_offset,
      rank: file_set.rank,
      representative_image_url: FileSets.representative_image_url_for(file_set),
      role: file_set.role.label,
      streaming_url: FileSets.distribution_streaming_uri_for(file_set),
      visibility: file_set.work.visibility.label,
      work_id: file_set.work_id
    }
  end

  def api_url, do: Application.get_env(:meadow, :dc_api) |> get_in([:v2, "base_url"])

  def extracted_metadata(%{"exif" => _} = value), do: ExtractedMetadata.transform(value)
  def extracted_metadata(%{"mediainfo" => _}), do: nil
  def extracted_metadata(value), do: value
end
