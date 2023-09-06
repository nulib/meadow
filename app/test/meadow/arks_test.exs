defmodule Meadow.ArksTest do
  use Meadow.DataCase

  alias Meadow.Arks

  describe "mint_ark/1" do
    setup %{work_type: work_type} do
      {:ok, work: work_fixture(%{work_type: %{id: work_type, scheme: "work_type"}})}
    end

    seed_values("coded_terms/work_type")
    |> Enum.each(fn %{id: work_type} ->
      @tag work_type: work_type
      test "mint_ark/1 mints an ark for #{work_type} work type", %{work: work} do
        assert {:ok, %{descriptive_metadata: %{ark: ark}}} = Arks.mint_ark(work)
        assert is_binary(ark)
      end

      @tag work_type: work_type
      test "mint_ark!/1 mints an ark for #{work_type} work type", %{work: work} do
        assert Arks.mint_ark!(work)
      end
    end)
  end
end
