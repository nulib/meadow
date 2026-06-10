defmodule Meadow.ArchivesSpace.Digital do
  @moduledoc """
  Pulls ArchivesSpace digital object images into Meadow's ingest bucket.

  An archival object references digital objects through its `instances`
  array (`instance_type: "digital_object"`, `digital_object.ref` pointing
  at `/repositories/:repo_id/digital_objects/:id`). Each digital object
  carries one or more `file_versions`, whose `file_uri` is the image URL.

  `ingest_file_sets/2` resolves those digital objects, downloads each image
  into the Meadow ingest bucket — the same bucket a CSV ingest uploads to,
  so the digest-tag lambda tags the object exactly as it would a normal
  upload — and returns file set attribute maps ready to embed in a work
  changeset, along with which one ArchivesSpace marks representative.
  Individual file versions that fail to download are logged and skipped
  rather than aborting the whole import.
  """

  alias Meadow.ArchivesSpace.Client
  alias Meadow.Config

  require Logger

  @doc """
  Builds access-role file set attribute maps for an archival object's
  digital object images, copying each image into the ingest bucket.

  `accession_number` is the parent work's accession number; each file set
  gets a deterministic `"\#{accession_number}:\#{index}"` accession number so
  re-imports remain idempotent.

  Returns `{file_sets, representative_accession_number}`. The representative
  accession number is the file set ArchivesSpace marks as representative
  (`nil` when nothing is flagged, so Meadow's default applies), determined
  from `is_representative` on both the digital object `instance` and the
  `file_version` — see `representative_score/2`. The importer hands that
  accession number to `Works.set_representative_image!/2`, the same way a CSV
  ingest honors its `work image` column.
  """
  def ingest_file_sets(archival_object, accession_number) do
    tagged =
      archival_object
      |> digital_object_instances()
      |> Enum.flat_map(&instance_file_versions/1)
      |> Enum.with_index()
      |> Enum.map(fn {{file_version, instance_representative?}, index} ->
        case build_file_set(file_version, accession_number, index) do
          nil -> nil
          file_set -> {file_set, representative_score(file_version, instance_representative?)}
        end
      end)
      |> Enum.reject(&is_nil/1)

    {Enum.map(tagged, &elem(&1, 0)), representative_accession(tagged)}
  end

  # The accession number of the highest-scoring representative file set, or nil
  # when nothing carries a representative flag (score 0). On ties (e.g. several
  # flagged file versions) the first in document order wins.
  defp representative_accession(tagged) do
    tagged
    |> Enum.filter(fn {_file_set, score} -> score > 0 end)
    |> Enum.max_by(fn {_file_set, score} -> score end, fn -> nil end)
    |> case do
      nil -> nil
      {file_set, _score} -> file_set.accession_number
    end
  end

  # A representative file version outranks a merely-representative instance, and
  # a representative file version inside the representative instance outranks
  # all. 0 means "not flagged".
  defp representative_score(file_version, instance_representative?) do
    file_version_score = if Map.get(file_version, "is_representative", false), do: 2, else: 0
    instance_score = if instance_representative?, do: 1, else: 0
    file_version_score + instance_score
  end

  defp digital_object_instances(archival_object) do
    archival_object
    |> Map.get("instances", [])
    |> Enum.filter(&(Map.get(&1, "instance_type") == "digital_object"))
  end

  # Pairs each of an instance's image file versions with whether the instance
  # itself is flagged representative, so the score can weigh both.
  defp instance_file_versions(instance) do
    case get_in(instance, ["digital_object", "ref"]) do
      nil ->
        []

      ref ->
        instance_representative? = Map.get(instance, "is_representative", false)
        ref |> file_versions() |> Enum.map(&{&1, instance_representative?})
    end
  end

  defp file_versions(ref) do
    case Client.get_record(ref) do
      {:ok, %{"file_versions" => versions}} when is_list(versions) ->
        Enum.filter(versions, &image_file_version?/1)

      {:ok, _record} ->
        []

      {:error, reason} ->
        Logger.warning("Could not load ArchivesSpace digital object #{ref}: #{inspect(reason)}")
        []
    end
  end

  defp image_file_version?(%{"file_uri" => uri}) when is_binary(uri), do: uri != ""
  defp image_file_version?(_), do: false

  defp build_file_set(%{"file_uri" => file_uri}, accession_number, index) do
    filename = filename_for(file_uri)
    key = "archivesspace/#{sanitize(accession_number)}/#{filename}"

    case store_image(file_uri, key) do
      :ok ->
        %{
          accession_number: "#{accession_number}:#{index}",
          role: %{id: "A", scheme: "file_set_role"},
          core_metadata: %{
            location: "s3://#{Config.ingest_bucket()}/#{key}",
            original_filename: filename,
            label: filename
          }
        }

      :error ->
        nil
    end
  end

  # Downloads an image and writes it to the ingest bucket. Overridable via
  # application env so tests can avoid the network and S3.
  defp store_image(file_uri, key) do
    case Application.get_env(:meadow, :archives_space_image_store) do
      nil -> default_store_image(file_uri, key)
      fun when is_function(fun, 2) -> fun.(file_uri, key)
    end
  end

  defp default_store_image(file_uri, key) do
    with {:ok, %{status: 200, body: body}} <- Req.get(file_uri, retry: false),
         {:ok, _} <- Config.ingest_bucket() |> ExAws.S3.put_object(key, body) |> ExAws.request() do
      :ok
    else
      {:ok, %{status: status}} ->
        Logger.error(
          "ArchivesSpace digital object download failed for #{file_uri}: HTTP #{status}"
        )

        :error

      {:error, reason} ->
        Logger.error(
          "Could not copy ArchivesSpace image #{file_uri} to ingest bucket: #{inspect(reason)}"
        )

        :error
    end
  end

  defp filename_for(file_uri) do
    file_uri
    |> URI.parse()
    |> Map.get(:path)
    |> case do
      nil -> "image"
      path -> Path.basename(path)
    end
  end

  defp sanitize(value), do: String.replace(value, ~r/[^A-Za-z0-9._-]+/, "_")
end
