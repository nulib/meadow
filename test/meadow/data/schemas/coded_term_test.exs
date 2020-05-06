defmodule Meadow.Data.Schemas.CodedTermTest do
  @moduledoc false
  use Meadow.DataCase

  alias Meadow.Data.Schemas.CodedTerm

  describe "coded_terms" do
    @valid_attrs %{
      id: "test",
      scheme: "test",
      label: "test"
    }

    test "valid attributes" do
      {:ok, coded_term} =
        %CodedTerm{}
        |> CodedTerm.changeset(@valid_attrs)
        |> Repo.insert()

      assert Map.get(@valid_attrs, :id) == coded_term.id
    end
  end
end
