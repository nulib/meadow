defmodule Meadow.Data.Schemas.ControlledMetadataEntryTest do
  @moduledoc false
  use Meadow.DataCase

  alias Meadow.Data.Schemas.ControlledMetadataEntry

  describe "controlled_metadata_entries" do
    @valid_attrs %{
      object_id: Ecto.UUID.generate(),
      role_id: "test",
      field_id: "test",
      value_id: "test"
    }

    @invalid_attrs %{
      object_id: "test"
    }

    test "valid attributes" do
      assert {:ok, controlled_metadata_entry} =
               %ControlledMetadataEntry{}
               |> ControlledMetadataEntry.changeset(@valid_attrs)
               |> Repo.insert()
    end

    test "invalid attributes" do
      assert {:error, %Ecto.Changeset{}} =
               %ControlledMetadataEntry{}
               |> ControlledMetadataEntry.changeset(@invalid_attrs)
               |> Repo.insert()
    end
  end
end
