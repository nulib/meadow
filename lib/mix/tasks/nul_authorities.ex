NimbleCSV.define(CSVParser, separator: "\,", escape: "\"")

defmodule Mix.Tasks.NulAuthorities.Clear do
  @moduledoc """
  Clear NUL Authorities
  """
  use Mix.Task
  alias Meadow.Repo
  alias NUL.Schemas.AuthorityRecord
  require Logger

  @shortdoc @moduledoc
  def run(_) do
    System.put_env("MEADOW_PROCESSES", "none")
    Application.ensure_all_started(:hackney)
    Mix.Task.run("app.start")
    Logger.configure(level: :info)

    with {deleted, _} <- AuthorityRecord |> Repo.delete_all() do
      Logger.info("#{deleted} records deleted")
    end
  after
    System.delete_env("MEADOW_PROCESSES")
  end
end

defmodule Mix.Tasks.NulAuthorities.Retrieve do
  @moduledoc """
  Retrieve NUL Authorities from Elasticsearch
  """
  use Mix.Task

  alias Meadow.Config

  require HTTPoison.Retry
  require Logger

  @query %{
    "_source" => ["id", "subject", "contributor", "creator"],
    "query" => %{
      "bool" => %{
        "must" => [
          %{"match" => %{"model.name" => "Work"}},
          %{"match" => %{"model.application" => "NextGen"}}
        ]
      }
    },
    "size" => "10000"
  }

  @headers [{"Content-Type", "application/json"}]

  @shortdoc @moduledoc
  def run([]), do: run(["nul_authorities_export.csv"])

  def run([key]) do
    System.put_env("MEADOW_PROCESSES", "none")

    case System.get_env("ELASTICSEARCH_URL") do
      nil ->
        Logger.error("ELASTICSEARCH_URL missing")

      base_url ->
        Application.ensure_all_started(:hackney)
        Mix.Task.run("app.start")
        Logger.configure(level: :info)
        import!(base_url, key)
    end
  after
    System.delete_env("MEADOW_PROCESSES")
  end

  defp import!(base_url, key) do
    data =
      extract_unique(base_url)
      |> Enum.sort_by(fn string ->
        string
        |> String.normalize(:nfd)
        |> String.downcase()
        |> String.replace(~r/^[^a-z]+/, "")
      end)
      |> Stream.map(fn label -> ["info:nul/" <> Ecto.UUID.generate(), label] end)
      |> CSVParser.dump_to_stream()
      |> Stream.map(&IO.iodata_to_binary/1)
      |> Enum.join("")

    ExAws.S3.put_object(Config.upload_bucket(), key, data)
    |> ExAws.request!()

    Logger.info("Done. Look for your export in bucket: #{Config.upload_bucket()}, key: #{key}")
  end

  def extract_unique(base_url) do
    stream(base_url)
    |> Stream.flat_map(fn %{"_source" => doc} ->
      ((doc |> Map.get("subject") |> extract_uris("subject")) ++
         (doc |> Map.get("creator") |> extract_uris("nul_creator")) ++
         (doc
          |> Map.get("contributor")
          |> extract_uris("nul_contributor")
          |> Enum.map(&Regex.replace(~r/ \(Contributor\)$/, &1, ""))))
      |> List.flatten()
    end)
    |> Stream.uniq()
  end

  defp extract_uris(nil, _), do: []

  defp extract_uris(terms, role) do
    terms
    |> Enum.filter(fn
      %{"role" => ^role} -> true
      _ -> false
    end)
    |> Enum.map(fn %{"label" => label} -> label end)
  end

  defp stream(base_url) do
    Stream.resource(
      fn -> first(base_url) end,
      fn cursor -> next(base_url, cursor) end,
      fn _ -> :ok end
    )
  end

  defp first(base_url) do
    post!(base_url, "/_search?scroll=1m", @query)
    |> Map.get(:body)
    |> Jason.decode!()
  end

  defp next(base_url, %{"_scroll_id" => scroll_id, "hits" => %{"hits" => hits}})
       when is_list(hits) and length(hits) > 0 do
    {
      hits,
      post!(base_url, "/_search/scroll", %{scroll: "1m", scroll_id: scroll_id})
      |> Map.get(:body)
      |> Jason.decode!()
    }
  end

  defp next(_, _), do: {:halt, nil}

  defp post!(base_url, path, data) do
    with url <- URI.parse(base_url) |> Map.put(:path, path) |> URI.to_string() do
      case HTTPoison.post(url, Jason.encode!(data), @headers)
           |> HTTPoison.Retry.autoretry() do
        {:ok, response} -> response
        {:error, :timeout} -> post!(base_url, path, data)
        {:error, error} -> raise error
      end
    end
  end
end

defmodule Mix.Tasks.NulAuthorities.Import do
  @moduledoc """
  Import NUL Authorities from a CSV
  """
  require Logger
  alias Meadow.{Config, Repo}
  alias NimbleCSV.RFC4180, as: CSV
  alias NUL.Schemas.AuthorityRecord

  def run([filename]) do
    System.put_env("MEADOW_PROCESSES", "none")
    Application.ensure_all_started(:hackney)
    Mix.Task.run("app.start")

    Logger.info("Looking for CSV in bucket: #{Config.upload_bucket()}, key: #{filename}")

    case Config.upload_bucket()
         |> ExAws.S3.get_object(filename)
         |> ExAws.request() do
      {:error, _} ->
        Logger.error(
          "Error loading: #{filename}. Make sure your file is in the correct bucket: #{
            Config.upload_bucket()
          }"
        )

      {:ok, csv} ->
        create_records(csv)
        Logger.info("Done")
    end
  after
    System.delete_env("MEADOW_PROCESSES")
  end

  defp create_records(csv) do
    Repo.transaction(fn ->
      CSV.parse_string(csv.body, skip_headers: false)
      |> Enum.map(fn
        [id | [label]] -> %{id: id, label: label}
        [label] -> %{id: "info:nul/" <> Ecto.UUID.generate(), label: label}
      end)
      |> Enum.map(
        &Map.merge(&1, %{
          inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
          updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
        })
      )
      |> Enum.chunk_every(5_000)
      |> Enum.each(fn chunk ->
        Repo.insert_all(AuthorityRecord, chunk, on_conflict: :nothing)
      end)
    end)
  end
end

defmodule Mix.Tasks.NulAuthorities.Export do
  @moduledoc """
  Export NUL Authorities to CSV
  """
  require Logger
  alias Meadow.{Config, Repo}
  alias NUL.Schemas.AuthorityRecord

  def run([]), do: run(["nul_authorities_export.csv"])

  def run([key]) do
    System.put_env("MEADOW_PROCESSES", "none")
    Application.ensure_all_started(:hackney)
    Mix.Task.run("app.start")

    data =
      AuthorityRecord
      |> Repo.all()
      |> Enum.map(fn record -> [record.id, record.label] end)
      |> CSVParser.dump_to_iodata()
      |> Enum.map(&IO.iodata_to_binary/1)
      |> Enum.join("")

    ExAws.S3.put_object(Config.upload_bucket(), key, data)
    |> ExAws.request!()

    Logger.info("Done. Look for your export in bucket: #{Config.upload_bucket()}, key: #{key}")
  after
    System.delete_env("MEADOW_PROCESSES")
  end
end
