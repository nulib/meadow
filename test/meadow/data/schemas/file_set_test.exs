defmodule Meadow.Data.Schemas.FileSetTest do
  use Meadow.DataCase

  alias Meadow.Data.Schemas.FileSet

  describe "file_sets" do
    @valid_attrs %{
      accession_number: "12345",
      role: "am",
      metadata: %{
        description: "yes",
        location: "https://example.com",
        original_filename: "test.tiff"
      }
    }

    test "created file_set has a UUID identifier" do
      {:ok, file_set} =
        %FileSet{}
        |> FileSet.changeset(@valid_attrs)
        |> Repo.insert()

      assert {:ok, <<_data::binary-size(16)>>} = Ecto.UUID.dump(file_set.id)
    end
  end
end
