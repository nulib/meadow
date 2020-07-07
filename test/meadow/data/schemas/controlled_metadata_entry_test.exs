defmodule Meadow.Data.Schemas.ControlledMetadataEntryTest do
  @moduledoc false
  use Meadow.DataCase

  alias Authoritex.Mock
  alias Meadow.Data.Schemas.ControlledMetadataEntry

  @valid_attrs %{
    object_id: Ecto.UUID.generate(),
    role: %{id: "aut", scheme: "marc_relator"},
    term: %{id: "mock:result1"}
  }

  @invalid_attrs %{
    object_id: Ecto.UUID.generate(),
    role: %{id: "aut", scheme: "marc_relator"},
    term: %{id: "wrong"}
  }

  describe "changeset" do
    setup do
      Mock.set_data([
        %{
          id: "mock:result1",
          label: "First Result",
          qualified_label: "First Result (1)",
          hint: "(1)"
        }
      ])

      :ok
    end

    test "with valid attributes is successful" do
      changeset = %ControlledMetadataEntry{} |> ControlledMetadataEntry.changeset(@valid_attrs)
      assert changeset.valid?
    end

    test "with invalid attributes is not successful" do
      changeset = %ControlledMetadataEntry{} |> ControlledMetadataEntry.changeset(@invalid_attrs)
      refute changeset.valid?
    end
  end
end
