defmodule Meadow.Utils.DataLoader do
  @moduledoc """
  Insert dummy Work records (100 by default, can be overridden),
  with embedded Metadata and a random array of up to 300 FileSets.
  """

  alias Meadow.Repo

  alias Meadow.Data.Schemas.{
    FileSet,
    FileSetMetadata,
    Work,
    WorkDescriptiveMetadata
  }

  use Meadow.Constants

  def insert_data(work_count \\ 100) do
    1..work_count
    |> Enum.each(fn _ -> insert_work() end)
  end

  defp insert_work do
    Repo.insert!(%Work{
      accession_number: Faker.String.base64(),
      descriptive_metadata: %WorkDescriptiveMetadata{
        description: [Faker.Lorem.sentence()],
        keywords: Faker.Lorem.words(1..5),
        title: Faker.Lorem.sentence()
      },
      file_sets: insert_file_sets()
    })
  end

  defp insert_file_sets do
    1..Enum.random(2..50)
    |> Enum.map(fn _ ->
      %FileSet{
        accession_number: Faker.String.base64(),
        metadata: %FileSetMetadata{
          location: "https://fake-s3-bucket/" <> Faker.String.base64(),
          original_filename: Faker.File.file_name()
        }
      }
    end)
  end
end
