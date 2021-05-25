defmodule Meadow.Data.Schemas.FileSetTest do
  use Meadow.DataCase

  alias Meadow.Data.Schemas.FileSet

  import ExUnit.CaptureLog

  describe "file_sets" do
    @valid_attrs %{
      accession_number: "12345",
      role: %{id: "A", scheme: "FILE_SET_ROLE"},
      core_metadata: %{
        description: "yes",
        location: "https://example.com",
        original_filename: "test.tiff"
      }
    }

    setup do
      {:ok, file_set} =
        %FileSet{}
        |> FileSet.changeset(@valid_attrs)
        |> Repo.insert()

      {:ok, %{file_set: file_set}}
    end

    test "created file_set has a UUID identifier", %{file_set: file_set} do
      assert {:ok, <<_data::binary-size(16)>>} = Ecto.UUID.dump(file_set.id)
    end

    test "Rename metadata to core_metadata", %{file_set: file_set} do
      log =
        capture_log(fn ->
          changeset =
            file_set |> FileSet.changeset(%{metadata: %{description: "New Description"}})

          assert changeset.valid?
          assert changeset.changes.core_metadata.changes.description == "New Description"
        end)

      assert log =~ ~r/Renaming to :core_metadata/
    end

    test "Ignore metadata if core_metadata is present", %{file_set: file_set} do
      log =
        capture_log(fn ->
          changeset =
            file_set
            |> FileSet.changeset(%{
              metadata: %{description: "Metadata Description"},
              core_metadata: %{description: "Core Metadata Description"}
            })

          assert changeset.valid?

          assert changeset.changes.core_metadata.changes.description ==
                   "Core Metadata Description"
        end)

      assert log =~ ~r/Ignoring :metadata/
    end
  end
end
