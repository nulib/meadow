defmodule Meadow.Data.Types.EDTFDateTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Meadow.Data.Types.EDTFDate

  @edtf "1975-07-01"
  @humanized "July 1, 1975"
  @value %{edtf: @edtf, humanized: @humanized}

  describe "type/0" do
    test "the column holds only the EDTF string" do
      assert EDTFDate.type() == :string
    end
  end

  describe "cast/1" do
    test "casts a bare EDTF string, deriving the humanized rendering" do
      assert EDTFDate.cast(@edtf) == {:ok, @value}
    end

    test "casts a map in either key style" do
      assert EDTFDate.cast(%{edtf: @edtf}) == {:ok, @value}
      assert EDTFDate.cast(%{"edtf" => @edtf}) == {:ok, @value}
    end

    test "recomputes humanized rather than trusting the incoming value" do
      assert EDTFDate.cast(%{edtf: @edtf, humanized: "whatever the client sent"}) ==
               {:ok, @value}
    end

    test "humanizes an approximate date" do
      assert {:ok, %{humanized: "circa 1968"}} = EDTFDate.cast("~1968")
    end

    test "rejects an unparseable date, naming the field's problem" do
      assert EDTFDate.cast("bad_date") == {:error, [message: "is not a valid EDTF date"]}
    end

    test "rejects a blank date in every shape" do
      assert EDTFDate.cast("") == {:error, [message: "cannot be blank"]}
      assert EDTFDate.cast(%{edtf: ""}) == {:error, [message: "cannot be blank"]}
      assert EDTFDate.cast(%{"edtf" => ""}) == {:error, [message: "cannot be blank"]}
    end

    test "passes nil through and rejects a non-date" do
      assert EDTFDate.cast(nil) == {:ok, nil}
      assert EDTFDate.cast(1234) == {:error, [message: "Invalid edtf type"]}
    end
  end

  describe "dump/1" do
    test "stores only the EDTF string, from any shape" do
      assert EDTFDate.dump(@value) == {:ok, @edtf}
      assert EDTFDate.dump(%{"edtf" => @edtf}) == {:ok, @edtf}
      assert EDTFDate.dump(@edtf) == {:ok, @edtf}
    end

    test "passes nil through and refuses anything else" do
      assert EDTFDate.dump(nil) == {:ok, nil}
      assert EDTFDate.dump(134_524) == :error
      assert EDTFDate.dump(%{not_a_date: true}) == :error
    end
  end

  describe "load/1" do
    test "derives humanized from the stored string" do
      assert EDTFDate.load(@edtf) == {:ok, @value}
    end

    test "degrades to the raw string rather than failing the load" do
      # A stored value was valid when written, so a humanizer change must not
      # make the row unreadable
      assert EDTFDate.load("bad_date") == {:ok, %{edtf: "bad_date", humanized: "bad_date"}}
    end

    test "passes nil through and refuses a non-string column value" do
      assert EDTFDate.load(nil) == {:ok, nil}
      assert EDTFDate.load(1234) == :error
    end
  end

  describe "edtf/1" do
    test "pulls the EDTF string out of any shape" do
      assert EDTFDate.edtf(@value) == @edtf
      assert EDTFDate.edtf(%{"edtf" => @edtf}) == @edtf
      assert EDTFDate.edtf(@edtf) == @edtf
      assert EDTFDate.edtf(nil) == nil
    end
  end

  describe "valid?/1" do
    test "reports whether a value can be cast" do
      assert EDTFDate.valid?(@edtf)
      assert EDTFDate.valid?(%{edtf: @edtf})
      refute EDTFDate.valid?("bad_date")
      refute EDTFDate.valid?("")
    end
  end

  describe "from_string/1" do
    test "wraps a bare string as params for CSV import and batches" do
      assert EDTFDate.from_string(@edtf) == %{edtf: @edtf}
    end
  end
end
