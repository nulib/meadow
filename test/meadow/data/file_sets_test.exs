defmodule Meadow.Data.FileSetsTest do
  use Meadow.DataCase

  alias Meadow.Data.FileSets
  alias Meadow.Data.FileSets.FileSet

  describe "queries" do
    @valid_attrs %{
      accession_number: "12345",
      metadata: %{location: "https://example.com", original_filename: "test.tiff"}
    }
    @invalid_attrs %{accession_number: nil}

    test "list_file_sets/0 returns all file_sets" do
      file_set_fixture()
      assert length(FileSets.list_file_sets()) == 1
    end

    test "create_file_set/1 with valid data creates a file_set" do
      assert {:ok, %FileSet{} = work} = FileSets.create_file_set(@valid_attrs)
    end

    test "create_file_set/1 with invalid data does not create a file_set" do
      assert {:error, %Ecto.Changeset{}} = FileSets.create_file_set(@invalid_attrs)
    end
  end
end
