defmodule Meadow.Data.PreservationCheckWriter do
  @moduledoc """
  Preforms a preservation check/report and uploads the csv report to the configured bucket in S3
  """

  alias Meadow.Config
  alias Meadow.Data.Schemas.Work
  alias Meadow.Repo
  alias Meadow.Utils.Pairtree
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

  @preservation_bucket Config.preservation_bucket()

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
          file_set_row_data(file_set, cache_key)
      end)
    end)
    |> CSV.dump_to_stream()
  end

  defp file_set_row_data(file_set, cache_key) do
    with result <- check_files(file_set) do
      record_invalid_file_set(result, cache_key)

      [
        file_set.id,
        file_set.metadata.label,
        file_set.role.id,
        Map.get(file_set.metadata.digests, "sha256"),
        Map.get(file_set.metadata.digests, "sha1"),
        file_set.metadata.location,
        Map.fetch!(result, :preservation),
        pyramid_uri_for(file_set),
        Map.fetch!(result, :pyramid)
      ]
    end
  end

  defp check_files(file_set) do
    %{
      :preservation => validate_preservation_file_present(file_set.metadata.location),
      :pyramid => validate_pyramid_present(file_set)
    }
  end

  defp record_invalid_file_set(%{:preservation => false, :pyramid => _}, cache_key),
    do: record_invalid_file_set(cache_key)

  defp record_invalid_file_set(%{:pyramid => false, :preservation => _}, cache_key),
    do: record_invalid_file_set(cache_key)

  defp record_invalid_file_set(_, _cache_key), do: :noop

  defp record_invalid_file_set(cache_key) do
    Cachex.incr(Meadow.Cache.PreservationChecks, cache_key)
  end

  defp validate_pyramid_present(%{role: %{id: "P"}}), do: "N/A"

  defp validate_pyramid_present(file_set) do
    validate_file_present(pyramid_uri_for(file_set))
  end

  defp validate_preservation_file_present(location) do
    %{host: bucket, path: "/" <> _key} = URI.parse(location)

    case bucket do
      @preservation_bucket ->
        validate_file_present(location)

      _ ->
        false
    end
  end

  defp validate_file_present(location) do
    with %{host: bucket, path: "/" <> key} <- URI.parse(location) do
      case ExAws.S3.head_object(bucket, key) |> ExAws.request() do
        {:ok, %{status_code: 200, headers: _headers}} ->
          true

        _ ->
          false
      end
    end
  end

  defp pyramid_uri_for(%{role: %{id: "P"}}), do: "N/A"

  defp pyramid_uri_for(file_set) do
    %URI{
      scheme: "s3",
      host: Config.pyramid_bucket(),
      path: Path.join(["/", Pairtree.pyramid_path(file_set.id)])
    }
    |> URI.to_string()
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
