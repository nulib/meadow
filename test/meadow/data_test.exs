defmodule Meadow.DataTest do
  use Meadow.DataCase

  alias Meadow.Data
  alias Meadow.Repo

  describe "queries" do
    @file_set_attrs %{
      file_sets: [
        %{
          accession_number: "1234",
          role: "am",
          metadata: %{
            description: "This is the description",
            location: "https://www.library.northwestern.edu",
            original_filename: "test.tiff"
          }
        }
      ]
    }

    test "get_work_by_file_set_id/1 fetches the work for that file_set" do
      work = work_fixture(@file_set_attrs) |> Repo.preload(:file_sets)
      file_set_id = List.first(work.file_sets).id
      assert Data.get_work_by_file_set_id(file_set_id).id == work.id
    end

    test "query/2 returns its queryable" do
      assert Data.query(:input, :ignored) == :input
    end
  end
end
