defmodule Meadow.Data.Schemas.DateCreatedEntryTest do
  @moduledoc false
  use Meadow.DataCase

  alias Meadow.Data.Schemas.DateCreatedEntry

  describe "changeset/3" do
    test "humanizes a bare EDTF string" do
      changeset = DateCreatedEntry.changeset(%DateCreatedEntry{}, "1999", 0)
      assert changeset.valid?

      assert %{edtf: "1999", humanized: "1999", position: 0} =
               Ecto.Changeset.apply_changes(changeset)
    end

    test "humanizes an {edtf} map" do
      changeset = DateCreatedEntry.changeset(%DateCreatedEntry{}, %{edtf: "~1899"}, 2)
      assert changeset.valid?

      assert %{edtf: "~1899", humanized: "circa 1899", position: 2} =
               Ecto.Changeset.apply_changes(changeset)
    end

    test "rejects an invalid EDTF string" do
      changeset = DateCreatedEntry.changeset(%DateCreatedEntry{}, "bad_date", 0)
      refute changeset.valid?
      assert %{edtf: ["is not a valid EDTF date"]} = errors_on(changeset)
    end

    test "requires a value" do
      changeset = DateCreatedEntry.changeset(%DateCreatedEntry{}, %{edtf: nil}, 0)
      refute changeset.valid?
      assert %{edtf: ["can't be blank"]} = errors_on(changeset)
    end
  end

  test "natural_key/1 is the EDTF string" do
    assert DateCreatedEntry.natural_key("2001") == "2001"
    assert DateCreatedEntry.natural_key(%{edtf: "2001", humanized: "2001"}) == "2001"
    assert DateCreatedEntry.natural_key(%DateCreatedEntry{edtf: "2001"}) == "2001"
  end
end
