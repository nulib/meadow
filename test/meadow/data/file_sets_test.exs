defmodule Meadow.Data.FileSetsTest do
  use Meadow.DataCase

  alias Meadow.Config
  alias Meadow.Data.FileSets
  alias Meadow.Data.Schemas.FileSet
  alias Meadow.Utils.ChangesetErrors

  describe "queries" do
    @valid_attrs %{
      accession_number: "12345",
      role: %{id: "A", scheme: "FILE_SET_ROLE"},
      core_metadata: %{
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
      assert {:ok, %FileSet{} = _file_set} = FileSets.create_file_set(@valid_attrs)
    end

    test "create_file_set/1 with invalid data does not create a file_set" do
      assert {:error, %Ecto.Changeset{}} = FileSets.create_file_set(@invalid_attrs)
    end

    test "delete_file_set/1 deletes a file_set" do
      file_set = file_set_fixture()
      assert {:ok, %FileSet{} = _file_set} = FileSets.delete_file_set(file_set)
      assert Enum.empty?(FileSets.list_file_sets())
    end

    test "update_file_set/2 updates a file_set" do
      file_set = file_set_fixture()

      assert {:ok, %FileSet{} = file_set} =
               FileSets.update_file_set(file_set, %{
                 core_metadata: %{description: "New description"}
               })

      assert file_set.core_metadata.description == "New description"
    end

    test "update_file_set/2 with invalid attributes returns an error" do
      file_set = file_set_fixture()

      assert {:error, %Ecto.Changeset{}} = FileSets.update_file_set(file_set, %{work_id: 123})
    end

    test "updating rank, role or accession_number with update_file_set/2 is not allowed" do
      file_set = file_set_fixture(%{role: %{id: "A", scheme: "FILE_SET_ROLE"}})

      assert {:ok, %FileSet{} = updated_file_set} =
               FileSets.update_file_set(file_set, %{
                 rank: 123,
                 core_metadata: %{label: "New label"},
                 accession_number: "Unsupported",
                 role: %{id: "P", scheme: "FILE_SET_ROLE"}
               })

      assert updated_file_set.core_metadata.label == "New label"
      assert updated_file_set.role.id == "A"
      assert updated_file_set.accession_number == file_set.accession_number
      assert updated_file_set.rank == file_set.rank
    end

    test "update_file_sets/1 updates multiple file_sets" do
      file_set1 = file_set_fixture()
      file_set2 = file_set_fixture()

      updates1 = %{id: file_set1.id, core_metadata: %{description: "New description"}}
      updates2 = %{id: file_set2.id, core_metadata: %{label: "New label"}}

      assert {:ok, [file_set1, file_set2]} = FileSets.update_file_sets([updates1, updates2])

      assert file_set1.core_metadata.description == "New description"
      assert file_set2.core_metadata.label == "New label"
    end

    test "update_file_sets/1 with bad data returns an error" do
      file_set1 = file_set_fixture()
      file_set2 = file_set_fixture()

      updates1 = %{id: file_set1.id, core_metadata: %{description: 900}}
      updates2 = %{id: file_set2.id, core_metadata: %{label: "New label"}}

      assert {:error, :index_1, %Ecto.Changeset{} = changeset} =
               FileSets.update_file_sets([updates1, updates2])

      refute changeset.valid?

      assert ChangesetErrors.error_details(changeset) == %{
               core_metadata: %{description: [%{error: "is invalid", value: "900"}]}
             }
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

  describe "utilities" do
    test "streaming_uri_for/1 for a FileSet with a 'P' role" do
      file_set = file_set_fixture(role: %{id: "P", scheme: "FILE_SET_ROLE"})
      assert is_nil(FileSets.streaming_uri_for(file_set))
    end

    test "streaming_uri_for/1 for a FileSet with any role besides 'P'" do
      file_set = file_set_fixture(role: %{id: "A", scheme: "FILE_SET_ROLE"})

      with uri <- file_set |> FileSets.streaming_uri_for() |> URI.parse() do
        assert uri.host == Config.streaming_bucket()
        assert uri.path |> String.length() == 55
      end
    end
  end
end
