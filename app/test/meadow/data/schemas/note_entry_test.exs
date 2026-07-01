defmodule Meadow.Data.Schemas.NoteEntryTest do
  @moduledoc false
  use Meadow.DataCase

  alias Meadow.Data.Schemas.NoteEntry

  @valid_attrs %{
    note: "This Note",
    type: %{id: "GENERAL_NOTE", scheme: "note_type"}
  }

  @invalid_attrs %{
    note: "This Note",
    type: %{id: "FORBIDDEN_NOTE", scheme: "note_type"}
  }

  describe "changeset/2" do
    test "with valid type" do
      changeset = %NoteEntry{} |> NoteEntry.changeset(@valid_attrs)

      assert changeset.valid?
    end

    test "with invalid type" do
      changeset = %NoteEntry{} |> NoteEntry.changeset(@invalid_attrs)

      refute changeset.valid?
    end

    test "with missing type" do
      changeset = %NoteEntry{} |> NoteEntry.changeset(%{note: "This Note"})

      refute changeset.valid?
    end

    test "is configured to autogenerate a binary_id primary key" do
      assert {:id, :id, :binary_id} = NoteEntry.__schema__(:autogenerate_id)
    end

    test "preserves a supplied id (so identity survives an edit)" do
      id = Ecto.UUID.generate()

      entry =
        %NoteEntry{id: id, note: "Original", type: %{id: "GENERAL_NOTE", scheme: "note_type"}}
        |> NoteEntry.changeset(%{id: id, note: "Edited", type: %{id: "GENERAL_NOTE", scheme: "note_type"}})
        |> Ecto.Changeset.apply_changes()

      assert entry.id == id
      assert entry.note == "Edited"
    end
  end

  describe "from_string/1" do
    test "qualified note" do
      assert "GENERAL_NOTE:This Note" |> NoteEntry.from_string() == @valid_attrs
    end

    test "invalid type" do
      assert "FORBIDDEN_NOTE:This Note" |> NoteEntry.from_string() == @invalid_attrs
    end

    test "missing type" do
      assert "This Note"
             |> NoteEntry.from_string() == %{
               note: "This Note",
               type: %{id: "", scheme: "note_type"}
             }
    end
  end
end
