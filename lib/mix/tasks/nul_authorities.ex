defmodule Mix.Tasks.NulAuthorities.Import do
  @moduledoc """
  Import NUL Authorities from a CSV
  """
  require Logger
  alias Meadow.{Config, Repo}
  alias NimbleCSV.RFC4180, as: CSV
  alias NUL.Schemas.AuthorityRecord

  def run([filename]) do
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
  end

  defp create_records(csv) do
    Repo.transaction(fn ->
      CSV.parse_string(csv.body, skip_headers: false)
      |> Enum.map(fn [label] ->
        %{
          id: "info:nul/" <> Ecto.UUID.generate(),
          label: label,
          inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second),
          updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
        }
      end)
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

  NimbleCSV.define(CSVParser, separator: "\,", escape: "\"")

  def run([]) do
    key = "nul_authorities_export.csv"

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
  end
end
