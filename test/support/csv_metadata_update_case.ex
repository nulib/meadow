defmodule Meadow.CSVMetadataUpdateCase do
  @moduledoc """
  This module provides the setup for tests that run CSV Metadata Updates
  """
  use ExUnit.CaseTemplate

  alias Meadow.Config
  import Meadow.TestHelpers

  setup tags do
    prewarm_controlled_term_cache()

    with bucket <- Config.upload_bucket(),
         key <- "csv_metadata/" <> Path.basename(tags[:source]),
         works <- Enum.map(1..44, fn _ -> work_fixture() end),
         content <- add_ids_to_csv(works, tags[:source]),
         source_url <- "s3://#{bucket}/#{key}" do
      {:ok,
       %{
         s3: [%{bucket: bucket, key: key, content: content}],
         source_url: source_url,
         works: works
       }}
    end
  end

  using do
    quote do
      use Meadow.S3Case
    end
  end

  defp add_ids_to_csv(works, file) do
    {headers, rows} =
      File.read!(file)
      |> String.split(~r/[\r\n]+/)
      |> Enum.split_while(fn row -> not Regex.match?(~r/\$ID\$/, row) end)

    rows =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {line, index} ->
        with work <- Enum.at(works, index) do
          line
          |> String.replace("$ID$", work.id)
          |> String.replace("$ACCESSION_NUMBER$", work.accession_number)
        end
      end)

    Enum.join(headers ++ rows, "\r\n")
  end
end
