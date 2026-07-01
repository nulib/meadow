defmodule Meadow.Data.Schemas.ValueEntryTest do
  @moduledoc """
  The CSV cell codec for identified free-text values: `uuid:value` out,
  `%{id, value}` back in, and anything that isn't exactly a UUID prefix is
  content, not identity.
  """
  use ExUnit.Case, async: true

  alias Meadow.Data.Schemas.ValueEntry

  @id "123e4567-e89b-12d3-a456-426614174000"

  describe "from_string/1" do
    test "decodes a uuid-prefixed item to its id and value" do
      assert ValueEntry.from_string("#{@id}:First value") == %{id: @id, value: "First value"}
    end

    test "keeps colons inside the value" do
      assert ValueEntry.from_string("#{@id}:Chicago: A History") ==
               %{id: @id, value: "Chicago: A History"}
    end

    test "normalizes an uppercase uuid prefix" do
      assert ValueEntry.from_string("#{String.upcase(@id)}:Value") == %{id: @id, value: "Value"}
    end

    test "text without a uuid prefix is the whole value, colons and all" do
      assert ValueEntry.from_string("Chicago: A History") == "Chicago: A History"
      assert ValueEntry.from_string("not-a-uuid:Value") == "not-a-uuid:Value"

      # Right length, wrong content: still not an id.
      assert ValueEntry.from_string("zzze4567-e89b-12d3-a456-426614174000:Value") ==
               "zzze4567-e89b-12d3-a456-426614174000:Value"
    end

    test "an empty cell item decodes to nothing" do
      assert ValueEntry.from_string("") == nil
    end
  end

  describe "to_csv_string/1" do
    test "encodes an identified entry as uuid:value" do
      assert ValueEntry.to_csv_string(%{"id" => @id, "value" => "First"}) == "#{@id}:First"
      assert ValueEntry.to_csv_string(%ValueEntry{id: @id, value: "First"}) == "#{@id}:First"
    end

    test "an entry without an id encodes as its bare value" do
      assert ValueEntry.to_csv_string(%{"value" => "First"}) == "First"
      assert ValueEntry.to_csv_string("First") == "First"
    end

    test "round trips" do
      assert "#{@id}:With: a colon" |> ValueEntry.from_string() |> ValueEntry.to_csv_string() ==
               "#{@id}:With: a colon"
    end
  end
end
