defmodule Meadow.Data.PreservationCheckWriter do
  @moduledoc """
  Preforms a preservation check/report and uploads the csv report to the configured bucket in S3
  """

  alias Meadow.Config
  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.Work
  alias Meadow.Repo
  alias NimbleCSV.RFC4180, as: CSV

  @headers [
    "work_id",
    "work_title",
    "file_set_id",
    "file_set_label",
    "file_set_role",
    "sha256",
    "sha1",
    "preservation_location",
    "preservation_exists",
    "pyramid_location",
    "pyramid_exists"
  ]

  def generate_report(filename) do
    cache_key = Ecto.UUID.generate()

    case generate_csv(cache_key) do
      {:ok, data} ->
        ExAws.S3.put_object(
          Config.preservation_check_bucket(),
          "#{filename}",
          data
        )
        |> ExAws.request!()

        {:ok, location(filename), failed_rows(cache_key)}

      {:error, _} ->
        {:error, "could not generate report"}
    end
  end

  defp failed_rows(cache_key) do
    case Cachex.get(Meadow.Cache.PreservationChecks, cache_key) do
      {:ok, nil} ->
        0

      {:ok, value} ->
        value
    end
  end

  defp generate_csv(cache_key) do
    Repo.transaction(
      fn ->
        Work
        |> stream_csv(cache_key)
        |> Enum.join("")
      end,
      timeout: :infinity
    )
  end

  defp stream_csv(schema, cache_key) do
    Stream.resource(
      fn -> :header end,
      fn
        nil ->
          {:halt, nil}

        :header ->
          {
            [@headers]
            |> CSV.dump_to_stream(),
            :rows
          }

        :rows ->
          {generate_rows(schema, cache_key), nil}
      end,
      fn _ -> :ok end
    )
    |> Stream.map(fn thing -> IO.iodata_to_binary(thing) end)
  end

  defp generate_rows(schema, cache_key) do
    schema
    |> Repo.stream()
    |> Stream.chunk_every(10)
    |> Stream.flat_map(fn chunk ->
      Repo.preload(chunk, Work.required_index_preloads())
    end)
    |> Stream.flat_map(fn work ->
      work.file_sets
      |> Stream.map(fn file_set ->
        [work.id, work.descriptive_metadata.title] ++
          file_set_row_data(file_set, cache_key, work.work_type.id)
      end)
    end)
    |> CSV.dump_to_stream()
  end

  defp file_set_row_data(file_set, cache_key, work_type_id) do
    with result <- check_files(file_set, work_type_id) do
      record_invalid_file_set(result, cache_key)

      [
        file_set.id,
        file_set.core_metadata.label,
        file_set.role.id,
        get_if_map(result.digests, "sha256"),
        get_if_map(result.digests, "sha1"),
        file_set.core_metadata.location,
        Map.fetch!(result, :preservation),
        FileSets.pyramid_uri_for(file_set),
        Map.fetch!(result, :pyramid)
      ]
    end
  end

  defp get_if_map(map, key) when is_map(map) do
    Map.get(map, key, "MISSING")
  end

  defp get_if_map(_, _), do: "MISSING"

  defp check_files(file_set, work_type) do
    %{
      :digests => file_set.core_metadata |> Map.get(:digests),
      :preservation => validate_preservation_file(file_set.core_metadata.location),
      :pyramid => validate_pyramid_present(file_set, work_type)
    }
  end

  defp record_invalid_file_set(%{preservation: false}, cache_key),
    do: record_invalid_file_set(cache_key)

  defp record_invalid_file_set(%{pyramid: false}, cache_key),
    do: record_invalid_file_set(cache_key)

  defp record_invalid_file_set(%{digests: digests}, cache_key) do
    case digests do
      %{"sha256" => <<_sha256::binary-size(64)>>, "sha1" => <<_sha1::binary-size(40)>>} -> :noop
      _ -> record_invalid_file_set(cache_key)
    end
  end

  defp record_invalid_file_set(_, _cache_key), do: :noop

  defp record_invalid_file_set(cache_key) do
    Cachex.incr(Meadow.Cache.PreservationChecks, cache_key)
  end

  defp validate_pyramid_present(%{role: %{id: "P"}}, _work_type_id), do: "N/A"
  defp validate_pyramid_present(%{role: %{id: "S"}}, _work_type_id), do: "N/A"
  defp validate_pyramid_present(%{role: %{id: "A"}}, "VIDEO"), do: "N/A"
  defp validate_pyramid_present(%{role: %{id: "A"}}, "AUDIO"), do: "N/A"

  defp validate_pyramid_present(file_set, _work_type_id) do
    case FileSets.pyramid_uri_for(file_set) do
      nil ->
        "N/A"

      uri ->
        Meadow.Utils.Stream.exists?(uri)
    end
  end

  defp validate_preservation_file(location) do
    %{host: bucket, path: "/" <> _key} = URI.parse(location)

    preservation_bucket = Config.preservation_bucket()

    case bucket do
      ^preservation_bucket ->
        Meadow.Utils.Stream.exists?(location)

      _ ->
        false
    end
  end

  defp location(key) do
    %URI{
      scheme: "s3",
      host: Config.preservation_check_bucket(),
      path: Path.join(["/", key])
    }
    |> URI.to_string()
  end
end
