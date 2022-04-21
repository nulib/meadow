defmodule Meadow.Data.Schemas.ControlledMetadataEntryTest do
  @moduledoc false
  use Meadow.AuthorityCase
  use Meadow.DataCase

  alias Meadow.Data.Schemas.ControlledMetadataEntry

  @valid_attrs %{
    object_id: Ecto.UUID.generate(),
    role: %{id: "aut", scheme: "marc_relator"},
    term: %{id: "mock1:result1"}
  }

  @invalid_attrs %{
    object_id: Ecto.UUID.generate(),
    role: %{id: "aut", scheme: "marc_relator"},
    term: %{id: "wrong"}
  }

  @valid_subject_attributes %{
    object_id: Ecto.UUID.generate(),
    role: %{id: "TOPICAL", scheme: "subject_role"},
    term: %{id: "mock1:result1"}
  }

  @invalid_subject_attributes %{
    object_id: Ecto.UUID.generate(),
    term: %{id: "mock1:result1"}
  }

  describe "changeset" do
    test "with valid attributes is successful" do
      changeset = %ControlledMetadataEntry{} |> ControlledMetadataEntry.changeset(@valid_attrs)
      assert changeset.valid?
    end

    test "with invalid attributes is not successful" do
      changeset = %ControlledMetadataEntry{} |> ControlledMetadataEntry.changeset(@invalid_attrs)
      refute changeset.valid?
    end
  end

  describe "changeset_with_role" do
    test "with valid attributes is successful" do
      changeset =
        %ControlledMetadataEntry{}
        |> ControlledMetadataEntry.changeset_with_role(@valid_subject_attributes)

      assert changeset.valid?
    end

    test "with invalid attributes is not successful" do
      changeset =
        %ControlledMetadataEntry{}
        |> ControlledMetadataEntry.changeset_with_role(@invalid_subject_attributes)

      refute changeset.valid?
    end
  end

  describe "from_string/1" do
    test "qualified subject" do
      assert "GEOGRAPHICAL:http://id.loc.gov/authorities/subjects/sh2002006395"
             |> ControlledMetadataEntry.from_string() == %{
               role: %{id: "GEOGRAPHICAL", scheme: "subject_role"},
               term: %{id: "http://id.loc.gov/authorities/subjects/sh2002006395"}
             }
    end

    test "unqualified subject" do
      assert "http://id.loc.gov/authorities/subjects/sh2002006395"
             |> ControlledMetadataEntry.from_string() == %{
               term: %{id: "http://id.loc.gov/authorities/subjects/sh2002006395"}
             }
    end

    test "marc relator" do
      assert "pbl:http://id.loc.gov/authorities/names/n79091588"
             |> ControlledMetadataEntry.from_string() == %{
               role: %{id: "pbl", scheme: "marc_relator"},
               term: %{id: "http://id.loc.gov/authorities/names/n79091588"}
             }
    end
  end
end
