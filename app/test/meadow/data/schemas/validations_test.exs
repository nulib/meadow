defmodule Meadow.Data.Schemas.ValidationsTest do
  use ExUnit.Case

  defmodule ChildSchema do
    use Ecto.Schema
    import Ecto.Changeset
    import Meadow.Data.Schemas.Validations

    embedded_schema do
      field :array_field, {:array, :string}, default: []
      field :string_field, :string, default: "default"
      field :number_field, :integer
    end

    def changeset(record, attrs) do
      record
      |> cast(attrs, [:array_field, :string_field, :number_field])
    end
  end

  defmodule ParentSchema do
    use Ecto.Schema
    import Ecto.Changeset
    import Meadow.Data.Schemas.Validations

    @primary_key {:id, :string, autogenerate: false}
    schema "owner" do
      field :name, :string
      field :order, :integer
      embeds_one :child_schema, ChildSchema, on_replace: :update
    end

    def changeset(record, attrs) do
      record
      |> cast(attrs, [:name, :order])
      |> prepare_assoc(:child_schema)
      |> cast_embed(:child_schema)
    end
  end

  setup tags do
    subject = %ParentSchema{
      id: "parent",
      name: "Parent Schema",
      order: 1,
      child_schema: %ChildSchema{
        array_field: ["a", "b", "c"],
        string_field: "d",
        number_field: 5
      }
    }

    change =
      subject
      |> ParentSchema.changeset(%{child_schema: tags[:child_param]})

    {:ok, %{subject: subject, changeset: Map.get(change.changes, :child_schema)}}
  end

  # Passing nil for an existing child leaves it untouched (a missing child
  # would be built empty instead)
  @tag child_param: nil
  test "child_schema: nil", %{changeset: changeset} do
    assert is_nil(changeset)
  end

  test "a missing child is built empty" do
    change = ParentSchema.changeset(%ParentSchema{id: "new"}, %{name: "New Parent"})
    assert %Ecto.Changeset{action: :insert, changes: changes} = change.changes.child_schema
    assert changes == %{}
  end

  # Passing a map of values as embedded changes updates the schema as expected
  @tag child_param: %{string_field: "New Value", number_field: 0}
  test "child_schema: %{values}", %{changeset: changeset} do
    refute is_nil(changeset)

    with values <- changeset.changes do
      refute Map.has_key?(values, :array_field)
      assert values.string_field == "New Value"
      assert values.number_field == 0
    end
  end

  # Passing an invalid map results in errors
  @tag child_param: %{array_field: "string"}
  test "invalid values", %{changeset: changeset} do
    refute is_nil(changeset)
    refute changeset.valid?
    assert {"is invalid", _} = changeset.errors[:array_field]
  end
end
