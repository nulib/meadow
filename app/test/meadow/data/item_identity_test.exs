defmodule Meadow.Data.ItemIdentityTest do
  @moduledoc """
  The identity rule for repeating metadata items, in isolation. The invariants:

    1. An echoed id always wins and is never reassigned.
    2. An id-less item claims the id of an existing item with the same natural
       key — so re-sending an unchanged list never remints identity.
    3. A changed value is new content: it is never paired to a dropped item by
       position, because a wrong pairing would fabricate provenance.
    4. Each existing id is claimed at most once; duplicate values pair in order.
  """
  use ExUnit.Case, async: true

  alias Meadow.Data.ItemIdentity

  describe "rehydrate/3 with value items" do
    @existing [
      %{"id" => "id-first", "value" => "First"},
      %{"id" => "id-second", "value" => "Second"}
    ]

    test "an unchanged value claims its existing id" do
      assert [%{"id" => "id-first", "value" => "First"}] =
               ItemIdentity.rehydrate(
                 [%{"value" => "First"}],
                 @existing,
                 &ItemIdentity.value_key/1
               )
    end

    test "a bare string is promoted and claims its existing id" do
      assert [%{"id" => "id-first", "value" => "First"}] =
               ItemIdentity.rehydrate(["First"], @existing, &ItemIdentity.value_key/1)
    end

    test "an echoed id is kept even when the value changed (in-place edit)" do
      assert [%{"id" => "id-first", "value" => "Edited"}] =
               ItemIdentity.rehydrate(
                 [%{"id" => "id-first", "value" => "Edited"}],
                 @existing,
                 &ItemIdentity.value_key/1
               )
    end

    test "a changed value without its id stays id-less — never paired by position" do
      # "Edited" replaced "First" in place, but without the echoed id there is
      # no safe way to know that: pairing it to the dropped item positionally is
      # exactly the reconcile-by-guess behavior this module exists to prevent.
      assert [%{"value" => "Edited"}, %{"id" => "id-second", "value" => "Second"}] =
               ItemIdentity.rehydrate(
                 [%{"value" => "Edited"}, %{"value" => "Second"}],
                 @existing,
                 &ItemIdentity.value_key/1
               )
    end

    test "an id echoed by one item is not claimable by another" do
      # The first item took id-first by echo (an edit); the second item's value
      # happens to match that edited item's old value but must not steal its id.
      assert [
               %{"id" => "id-first", "value" => "Edited"},
               %{"value" => "First"}
             ] =
               ItemIdentity.rehydrate(
                 [%{"id" => "id-first", "value" => "Edited"}, %{"value" => "First"}],
                 @existing,
                 &ItemIdentity.value_key/1
               )
    end

    test "duplicate values claim distinct ids, in order" do
      existing = [
        %{"id" => "id-a", "value" => "dup"},
        %{"id" => "id-b", "value" => "dup"}
      ]

      assert [%{"id" => "id-a"}, %{"id" => "id-b"}] =
               ItemIdentity.rehydrate(
                 [%{"value" => "dup"}, %{"value" => "dup"}],
                 existing,
                 &ItemIdentity.value_key/1
               )
    end

    test "a reordered unchanged list keeps every id" do
      assert [%{"id" => "id-second"}, %{"id" => "id-first"}] =
               ItemIdentity.rehydrate(
                 [%{"value" => "Second"}, %{"value" => "First"}],
                 @existing,
                 &ItemIdentity.value_key/1
               )
    end

    test "ids are stamped in the item's own key style" do
      assert [%{id: "id-first", value: "First"}] =
               ItemIdentity.rehydrate(
                 [%{value: "First"}],
                 @existing,
                 &ItemIdentity.value_key/1
               )
    end
  end

  describe "natural keys across shapes" do
    test "value_key matches structs, maps, and bare strings" do
      assert ItemIdentity.value_key("First") ==
               ItemIdentity.value_key(%{"id" => "x", "value" => "First"})

      assert ItemIdentity.value_key(%{value: "First"}) ==
               ItemIdentity.value_key(%{"value" => "First"})

      assert ItemIdentity.value_key(%{}) == nil
      assert ItemIdentity.value_key("") == nil
    end

    test "note_key is the type id plus exact text, whatever the key style" do
      stored = %{
        "id" => "x",
        "note" => "A note",
        "type" => %{"id" => "GENERAL_NOTE", "label" => "General Note", "scheme" => "note_type"}
      }

      decoded = %{note: "A note", type: %{id: "GENERAL_NOTE", scheme: "note_type"}}

      assert ItemIdentity.note_key(stored) == ItemIdentity.note_key(decoded)
      assert ItemIdentity.note_key(%{note: "A note"}) == nil

      refute ItemIdentity.note_key(%{note: "A note", type: %{id: "LOCAL_NOTE"}}) ==
               ItemIdentity.note_key(decoded)
    end

    test "related_url_key is the label id plus exact url" do
      stored = %{
        "id" => "x",
        "url" => "https://example.org",
        "label" => %{"id" => "RELATED_INFORMATION", "scheme" => "related_url"}
      }

      decoded = %{url: "https://example.org", label: %{id: "RELATED_INFORMATION"}}

      assert ItemIdentity.related_url_key(stored) == ItemIdentity.related_url_key(decoded)
      assert ItemIdentity.related_url_key(%{url: "https://example.org"}) == nil
    end

    test "value, note, and url keys never collide" do
      keys = [
        ItemIdentity.value_key("content"),
        ItemIdentity.note_key(%{note: "content", type: %{id: "content"}}),
        ItemIdentity.related_url_key(%{url: "content", label: %{id: "content"}})
      ]

      assert keys == Enum.uniq(keys)
    end
  end
end
