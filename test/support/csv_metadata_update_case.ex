defmodule Meadow.CSVMetadataUpdateCase do
  @moduledoc """
  This module provides the setup for tests that run CSV Metadata Updates
  """
  use ExUnit.CaseTemplate

  import Meadow.TestHelpers

  setup tags do
    :ok = sandbox_mode(tags)

    prewarm_controlled_term_cache()

    with works <- Enum.map(1..44, fn _ -> work_fixture() end),
         temp_file <- add_ids_to_csv(works, tags[:source]),
         source_url <- "file://#{temp_file}" do
      {:ok, %{source_url: source_url, works: works}}
    end
  end

  using do
    quote do
      use Meadow.DataCase
    end
  end

  defp add_ids_to_csv(works, file) do
    temp_file = Briefly.create!(extname: ".csv")

    [query | [headers | rows]] =
      File.read!(file)
      |> String.split(~r/[\r\n]+/)

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

    with csv <- Enum.join([query | [headers | rows]], "\r\n") do
      File.write!(temp_file, csv)
    end

    temp_file
  end
end
