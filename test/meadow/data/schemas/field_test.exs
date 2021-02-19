defmodule Meadow.Data.Schemas.FieldTest do
  @moduledoc false
  use Meadow.DataCase

  alias Meadow.Data.Schemas.Field

  describe "fields" do
    @valid_attrs %{
      id: "foo",
      label: "Foo",
      metadata_class: "descriptive",
      repeating: true,
      required: false
    }

    @invalid_attrs %{
      id: "test",
      label: "test",
      metadata_class: "test"
    }

    test "created work has a string identifier" do
      {:ok, field} =
        %Field{}
        |> Field.changeset(@valid_attrs)
        |> Repo.insert()

      assert Map.get(@valid_attrs, :id) == field.id
    end

    test "invalid attributes" do
      assert {:error, %Ecto.Changeset{}} =
               %Field{}
               |> Field.changeset(@invalid_attrs)
               |> Repo.insert()
    end
  end
end
