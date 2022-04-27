defmodule Meadow.Data.Schemas.ControlledValueTest do
  @moduledoc false
  use Meadow.DataCase

  alias Meadow.Data.Schemas.ControlledValue

  describe "controlled_values" do
    @valid_attrs %{
      id: "contributor",
      label: "Contributor"
    }

    @invalid_attrs %{
      id: "test"
    }

    test "created controlled value has a string identifier" do
      {:ok, controlled_value} =
        %ControlledValue{}
        |> ControlledValue.changeset(@valid_attrs)
        |> Repo.insert()

      assert Map.get(@valid_attrs, :id) == controlled_value.id
    end

    test "invalid attributes" do
      assert {:error, %Ecto.Changeset{}} =
               %ControlledValue{}
               |> ControlledValue.changeset(@invalid_attrs)
               |> Repo.insert()
    end
  end
end
