defmodule Meadow.Data.Schemas.ControlledMetadataEntryTest do
  @moduledoc false
  use Meadow.DataCase

  alias Meadow.Data.Schemas.ControlledMetadataEntry
  alias Meadow.Data.Types.ControlledTerm
  alias Authoritex.Mock

  @valid_attrs %{
    object_id: Ecto.UUID.generate(),
    role_id: "test",
    field_id: "test",
    value_id: "mock:result1"
  }

  describe "Insert" do
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
      assert {:ok, controlled_metadata_entry} =
               %ControlledMetadataEntry{}
               |> ControlledMetadataEntry.changeset(@valid_attrs)
               |> Repo.insert()
    end

    test "with invalid attributes is not successful" do
      attrs =
        @valid_attrs
        |> Map.delete(:field_id)
        |> Map.put(:value_id, "wrong")

      assert {:error,
              %Ecto.Changeset{
                errors: [
                  field_id: {"can't be blank", [validation: :required]},
                  value_id: {404, [type: ControlledTerm, validation: :cast]}
                ]
              }} =
               %ControlledMetadataEntry{}
               |> ControlledMetadataEntry.changeset(attrs)
               |> Repo.insert()
    end
  end
end
