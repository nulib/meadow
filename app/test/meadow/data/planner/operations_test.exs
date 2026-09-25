defmodule Meadow.Data.Planner.OperationsTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Meadow.Data.Planner.Operations

  defp rows(operations) do
    {:ok, rows} = Operations.to_rows(operations)
    rows
  end

  defp descriptive(operation, field, value),
    do: rows(%{operation => %{descriptive_metadata: %{field => value}}})

  describe "to_rows/1 with repeating free text" do
    test "encodes bare strings in order" do
      assert [
               %{value_kind: "string", value_text: "a", position: 0, field: "description"},
               %{value_kind: "string", value_text: "b", position: 1}
             ] = descriptive(:add, :description, ["a", "b"])
    end

    # Proposals recorded while repeating free text was stored as one row per
    # value hold `{id, value}` objects. The migration reads those documents as
    # they were written, so the codec has to accept both shapes.
    test "unwraps a value object with string keys" do
      assert [%{value_kind: "string", value_text: "a"}] =
               descriptive(:add, :description, [%{"value" => "a"}])
    end

    test "unwraps a value object with atom keys" do
      assert [%{value_kind: "string", value_text: "a"}] =
               descriptive(:add, :description, [%{value: "a"}])
    end

    test "ignores the row id that accompanied an edited value" do
      assert [%{value_kind: "string", value_text: "a"}] =
               descriptive(:add, :description, [%{"id" => "0d1e", "value" => "a"}])
    end

    test "unwraps a value object on a single-valued field" do
      assert [%{value_kind: "string", value_text: "T", position: nil, field: "title"}] =
               descriptive(:replace, :title, %{"value" => "T"})
    end

    test "mixes wrapped and bare values in one field" do
      assert [%{value_text: "a", position: 0}, %{value_text: "b", position: 1}] =
               descriptive(:add, :description, [%{"value" => "a"}, "b"])
    end
  end

  describe "to_rows/1 with other field kinds" do
    test "encodes an EDTF date from a bare string" do
      assert [%{value_kind: "edtf", edtf: "1975-07-01"}] =
               descriptive(:add, :date_created, ["1975-07-01"])
    end

    test "encodes a controlled term with a role" do
      assert [%{value_kind: "controlled", term_id: "http://example.org/1", role_id: "aut"}] =
               descriptive(:add, :contributor, [
                 %{"term" => %{"id" => "http://example.org/1"}, "role" => %{"id" => "aut"}}
               ])
    end

    test "rejects a field that cannot be proposed" do
      assert {:error, message} =
               Operations.to_rows(%{add: %{descriptive_metadata: %{nav_place: ["anything"]}}})

      assert message =~ "nav_place"
    end
  end
end
