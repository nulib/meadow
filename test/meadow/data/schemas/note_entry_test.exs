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
