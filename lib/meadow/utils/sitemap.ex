defmodule Meadow.Utils.Sitemap do
  @moduledoc """
  Generate and upload Digital Collection sitemaps
  """
  alias Meadow.Data.{Collections, Works}
  alias Meadow.Repo

  require Logger

  @doc """
  Generate a sitemap, upload it to the configured bucket, and optionally ping
  Google and Bing to tell them an update is available
  """
  def generate(ping \\ false) do
    with config <- config() do
      Repo.transaction(
        fn ->
          stream()
          |> Sitemapper.generate(config)
          |> Stream.map(fn {filename, data} -> {filename, IO.iodata_to_binary(data)} end)
          |> Stream.flat_map(&persist(&1, config))
          |> maybe_ping(config, ping)
          |> Stream.run()
        end,
        timeout: :infinity
      )
    end
  end

  defp maybe_ping(stream, _, false), do: stream
  defp maybe_ping(stream, config, true), do: Sitemapper.ping(stream, config)

  defp persist({filename, content}, config) do
    log_persist(filename, byte_size(content), Enum.into(config, %{}))
    Sitemapper.persist([{filename, content}], config)
  end

  defp log_persist(filename, bytes, %{store: Sitemapper.S3Store} = config) do
    with bucket <- config |> get_in([:store_config, :bucket]) do
      Logger.info("Uploading #{bytes} bytes to s3://#{bucket}/#{filename}")
    end
  end

  defp log_persist(filename, bytes, %{store: Sitemapper.FileStore} = config) do
    with path <- config |> get_in([:store_config, :path]) do
      Logger.info("Writing #{bytes} bytes to #{Path.join(path, filename)}")
    end
  end

  defp config, do: Application.get_env(:meadow, :sitemaps)

  def stream do
    [static_urls(), collection_urls(), work_urls()]
    |> Stream.concat()
  end

  defp static_urls do
    [
      %Sitemapper.URL{loc: expand_url("/"), priority: 0.5, changefreq: :daily},
      %Sitemapper.URL{loc: expand_url("/about"), priority: 0.5, changefreq: :weekly}
    ]
  end

  defp collection_urls do
    for collection <- Collections.list_collections() do
      %Sitemapper.URL{
        loc: expand_url("/collections/#{collection.id}"),
        priority: 0.5,
        changefreq: :daily
      }
    end
  end

  defp work_urls(limit \\ 50_000) do
    Works.work_query(visibility: "OPEN", work_type: "IMAGE", limit: limit)
    |> Repo.stream()
    |> Stream.map(fn work ->
      %Sitemapper.URL{
        loc: expand_url("/items/#{work.id}"),
        priority: 0.5,
        changefreq: :daily
      }
    end)
  end

  defp expand_url(path) do
    config()
    |> Keyword.get(:sitemap_url)
    |> URI.parse()
    |> URI.merge(path)
    |> URI.to_string()
  end

  # Rich content methods for when the Sitemap package
  # supports content type specific fields
  #
  #  defp add_image_details(opts, nil), do: opts
  #
  #  defp add_image_details(opts, work) do
  #    opts
  #    |> Keyword.put(:images, image_details(work))
  #  end
  #
  #  defp image_details(work) do
  #    [
  #      loc: thumbnail(work.representative_image),
  #      title: work.descriptive_metadata.title,
  #      license: license(work.descriptive_metadata.license),
  #      geo_location: location(work.descriptive_metadata.location)
  #    ]
  #    |> Enum.reject(fn {_, value} -> is_nil(value) end)
  #  end
  #
  #  defp license(nil), do: nil
  #  defp license(%{id: id}), do: id
  #
  #  defp thumbnail(nil), do: nil
  #  defp thumbnail(image), do: Path.join([image, "square/200,/0/default.jpg"])
  #
  #  defp location([%{term: %{label: result}} | _]), do: result
  #  defp location(_), do: nil
end
