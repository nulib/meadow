defmodule Meadow.DataTest do
  use Meadow.DataCase

  alias Meadow.Data
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Repo

  describe "queries" do
    @file_set_attrs %{
      file_sets: [
        %{
          accession_number: "1234",
          role: %{id: "A", scheme: "FILE_SET_ROLE"},
          core_metadata: %{
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

    test "ranked_file_sets_for_work/2 fetches the ranked file sets for a work and role" do
      work = work_fixture()

      %FileSet{}
      |> FileSet.changeset(%{
        work_id: work.id,
        accession_number: "2222",
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        core_metadata: %{location: "test", original_filename: "test"}
      })
      |> Repo.insert!()

      %FileSet{}
      |> FileSet.changeset(%{
        position: 0,
        work_id: work.id,
        accession_number: "1111",
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        core_metadata: %{location: "test", original_filename: "test"}
      })
      |> Repo.insert!()

      %FileSet{}
      |> FileSet.changeset(%{
        position: 0,
        work_id: work.id,
        accession_number: "no",
        role: %{id: "P", scheme: "FILE_SET_ROLE"},
        core_metadata: %{location: "test", original_filename: "test"}
      })
      |> Repo.insert!()

      %FileSet{}
      |> FileSet.changeset(%{
        position: 0,
        accession_number: "nono",
        role: %{id: "A", scheme: "FILE_SET_ROLE"},
        core_metadata: %{location: "test", original_filename: "test"}
      })
      |> Repo.insert!()

      [file_set_1, file_set_2] = Data.ranked_file_sets_for_work(work.id, "A")

      assert file_set_1.rank < file_set_2.rank
    end

    test "query/2 returns its queryable" do
      assert Data.query(:input, :ignored) == :input
    end
  end
end
