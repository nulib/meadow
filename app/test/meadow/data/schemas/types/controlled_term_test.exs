defmodule Meadow.Data.Types.ControlledTermTest do
  @moduledoc false
  use Meadow.AuthorityCase
  use Meadow.DataCase

  alias Meadow.Data.Types.ControlledTerm

  @controlled_term %{
    id: "http://id.loc.gov/authorities/names/nb2015010626",
    label: "Border Collie Trust Great Britain",
    variants: [
      "Border Collie Trust G.B.",
      "Border Collie Trust GB",
      "BCT G.B. (Border Collie Trust G.B.)",
      "BCT GB (Border Collie Trust G.B.)",
      "BCTGB (Border Collie Trust G.B.)"
    ]
  }

  describe "Meadow.Data.Types.ControlledTerm" do
    test "cast function" do
      assert {:ok, @controlled_term} == ControlledTerm.cast(@controlled_term)
      assert {:ok, @controlled_term} == ControlledTerm.cast(@controlled_term.id)
      assert ControlledTerm.cast(1234) == {:error, [message: "Invalid controlled term type"]}

      assert {:error, [message: :unknown_authority]} ==
               ControlledTerm.cast("totallywrong")
    end

    test "dump function" do
      assert ControlledTerm.dump(@controlled_term) == {:ok, @controlled_term.id}
      assert ControlledTerm.dump(134_524) == :error
    end

    test "load function" do
      assert ControlledTerm.load(@controlled_term.id) == {:ok, @controlled_term}

      assert ControlledTerm.load("bad-id") == {:ok, %{id: "bad-id", label: "", variants: []}}
    end
  end

  describe "geonames special case" do
    setup do
      {:ok,
       %{
         expected:
           {:ok, %{id: "https://sws.geonames.org/5347269/", label: "Faculty Glade", variants: []}}
       }}
    end

    test "URIs are correctly transformed", %{expected: expected} do
      assert ControlledTerm.cast("https://sws.geonames.org/5347269/") == expected
      assert ControlledTerm.cast("http://sws.geonames.org/5347269/") == expected
      assert ControlledTerm.cast("https://sws.geonames.org/5347269/") == expected
      assert ControlledTerm.cast("http://sws.geonames.org/5347269") == expected
    end
  end
end
