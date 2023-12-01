defmodule Meadow.Data.CSV.BulkImport do
  @moduledoc """
  Functions to bulk import CSV Metadata Updates using PostgreSQL
  COPY/UPDATE
  """

  alias Ecto.Adapters.SQL
  alias Meadow.Data.CSV.Import
  alias Meadow.Utils.Stream, as: StreamUtil
  alias NimbleCSV.RFC4180, as: CSV

  @chunk_size 500

  def import_stream(stream, job_id, repo \\ Meadow.Repo) do
    with temp_table <- "works_" <> String.replace(job_id, "-", "") do
      repo.transaction(
        fn ->
          repo.query("CREATE TEMP TABLE #{temp_table} (LIKE works)")

          try do
            stream
            |> stream_rows()
            |> Stream.map(fn chunk ->
              update_chunk(temp_table, job_id, chunk, repo)
            end)
            |> Stream.run()
          after
            repo.query("DROP TABLE #{temp_table}")
          end
        end,
        timeout: :infinity
      )
    end
  end

  def import_job(job) do
    job.source
    |> StreamUtil.stream_from()
    |> Import.read_csv()
    |> Import.stream()
    |> import_stream(job.id)
  end

  defp update_chunk(temp_table, job_id, stream, repo) do
    with [header_row] <- stream |> Enum.take(1),
         rows <- stream |> Stream.drop(1),
         set_clause <-
           header_row
           |> String.split(~r/\s*,\s*/)
           |> Enum.map_join(", ", &"#{&1} = #{temp_table}.#{&1}"),
         sql <-
           "COPY #{temp_table} (#{header_row}) FROM STDIN WITH (FORMAT CSV, NULL '')" do
      rows |> Enum.into(SQL.stream(repo, sql))
      # credo:disable-for-previous-line Credo.Check.Warning.UnusedEnumOperation

      repo.query(
        "UPDATE #{temp_table} SET inserted_at = works.inserted_at FROM works WHERE #{temp_table}.id = works.id"
      )

      repo.query(
        "UPDATE works SET #{set_clause} FROM #{temp_table} WHERE works.id = #{temp_table}.id"
      )

      repo.query(
        "INSERT INTO works_metadata_update_jobs (metadata_update_job_id, work_id) SELECT '#{job_id}', id FROM #{temp_table}"
      )

      repo.query("TRUNCATE TABLE #{temp_table}")
    end
  end

  defp stream_rows(stream) do
    with timestamp <- NaiveDateTime.utc_now() do
      stream
      |> Stream.map(fn entry ->
        entry
        |> put_in([:inserted_at], timestamp)
        |> put_in([:updated_at], timestamp)
        |> update_in([:descriptive_metadata, :id], &(&1 || Ecto.UUID.generate()))
        |> update_in([:administrative_metadata, :id], &(&1 || Ecto.UUID.generate()))
      end)
      |> Stream.chunk_every(@chunk_size)
      |> Stream.map(&stream_chunk_of_rows/1)
    end
  end

  defp stream_chunk_of_rows(chunk) do
    Stream.resource(
      fn -> :header end,
      fn
        nil ->
          {:halt, nil}

        :header ->
          {
            [chunk |> List.first() |> Map.keys() |> Enum.map(&to_string/1)]
            |> CSV.dump_to_stream(),
            :rows
          }

        :rows ->
          {
            chunk
            |> Enum.map(fn entry ->
              entry
              |> Enum.map(fn
                {_, %NaiveDateTime{} = v} -> NaiveDateTime.to_iso8601(v)
                {_, v} when is_list(v) or is_map(v) -> Jason.encode!(v)
                {_, v} -> to_string(v)
              end)
            end)
            |> CSV.dump_to_stream(),
            nil
          }
      end,
      fn _ -> :ok end
    )
    |> Stream.map(&IO.iodata_to_binary/1)
  end
end
