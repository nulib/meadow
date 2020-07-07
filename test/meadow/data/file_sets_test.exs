defmodule Meadow.Data.FileSetsTest do
  use Meadow.DataCase

  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.FileSet

  describe "queries" do
    @valid_attrs %{
      accession_number: "12345",
      role: "am",
      metadata: %{
        description: "yes",
        location: "https://example.com",
        original_filename: "test.tiff"
      }
    }

    @invalid_attrs %{accession_number: nil}

    test "list_file_sets/0 returns all file_sets" do
      file_set_fixture()
      assert length(FileSets.list_file_sets()) == 1
    end

    test "create_file_set/1 with valid data creates a file_set" do
      assert {:ok, %FileSet{} = file_set} = FileSets.create_file_set(@valid_attrs)
    end

    test "create_file_set/1 with invalid data does not create a file_set" do
      assert {:error, %Ecto.Changeset{}} = FileSets.create_file_set(@invalid_attrs)
    end

    test "delete_file_set/1 deletes a file_set" do
      file_set = file_set_fixture()
      assert {:ok, %FileSet{} = file_set} = FileSets.delete_file_set(file_set)
      assert Enum.empty?(FileSets.list_file_sets())
    end

    test "update_file_set/2 updates a file_set" do
      file_set = file_set_fixture()

      assert {:ok, %FileSet{} = file_set} =
               FileSets.update_file_set(file_set, %{metadata: %{description: "New description"}})

      assert file_set.metadata.description == "New description"
    end

    test "update_file_set/2 with invalid attributes returns an error" do
      file_set = file_set_fixture()

      assert {:error, %Ecto.Changeset{}} =
               FileSets.update_file_set(file_set, %{role: "Unsupported"})
    end

    test "get_file_set!/1 returns a file set by id" do
      file_set = file_set_fixture()
      assert FileSets.get_file_set!(file_set.id) == file_set
    end

    test "get_file_set_by_accession_number!/1 returns a file set by accession_number" do
      file_set = file_set_fixture()
      assert FileSets.get_file_set_by_accession_number!(file_set.accession_number) == file_set
    end

    test "get_file_set_with_work_and_sheet!/1 returns a file set with work and ingest sheet preloaded" do
      file_set = file_set_fixture() |> Repo.preload(:work)
      assert FileSets.get_file_set_with_work_and_sheet!(file_set.id) == file_set
    end

    test "accession_exists?/1 returns true if accession is already taken" do
      file_set = file_set_fixture()

      assert FileSets.accession_exists?(file_set.accession_number) == true
    end

    test "compute_positions/1 dynamically sets position values" do
      assert FileSets.compute_positions([%{position: nil}, %{position: nil}]) == [
               %{position: 0},
               %{position: 1}
             ]
    end
  end
end
