defmodule Meadow.Data.Types.ControlledTermTest do
  @moduledoc false
  use Meadow.AuthorityCase
  use Meadow.DataCase

  alias Meadow.Data.Types.ControlledTerm

  @controlled_term %{
    id: "http://id.loc.gov/authorities/names/nb2015010626",
    label: "Border Collie Trust Great Britain"
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

      assert ControlledTerm.load(1234) == :error
    end
  end
end
