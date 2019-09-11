defmodule Meadow.Data.FileSets.FileSetTest do
  use Meadow.DataCase

  alias Meadow.Data.FileSets.FileSet

  describe "file_sets" do
    @valid_attrs %{
      accession_number: "12345",
      metadata: %{location: "https://example.com", original_filename: "test.tiff"}
    }

    test "created file_set has a ULID identifier" do
      {:ok, file_set} =
        %FileSet{}
        |> FileSet.changeset(@valid_attrs)
        |> Repo.insert()

      assert {:ok, <<data::binary-size(16)>>} = Ecto.ULID.dump(file_set.id)
    end
  end
end
