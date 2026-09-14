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

  @uuid_a "123e4567-e89b-12d3-a456-426614174000"
  @uuid_b "123e4567-e89b-12d3-a456-426614174001"
  @uuid_foreign "123e4567-e89b-12d3-a456-426614174099"

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

  describe "reconcile/3 at untrusted write boundaries" do
    @existing_uuid [
      %{"id" => @uuid_a, "value" => "First"},
      %{"id" => @uuid_b, "value" => "Second"}
    ]

    test "accepts an echoed id owned by the current field" do
      assert {:ok, [%{"id" => @uuid_a, "value" => "Edited"}]} =
               ItemIdentity.reconcile(
                 [%{"id" => @uuid_a, "value" => "Edited"}],
                 @existing_uuid,
                 &ItemIdentity.value_key/1
               )
    end

    test "rejects an id copied from outside the current field" do
      assert {:error, {:foreign_id, @uuid_foreign}} =
               ItemIdentity.reconcile(
                 [%{"id" => @uuid_foreign, "value" => "Copied"}],
                 @existing_uuid,
                 &ItemIdentity.value_key/1
               )
    end

    test "rejects a duplicate echoed id" do
      assert {:error, {:duplicate_id, @uuid_a}} =
               ItemIdentity.reconcile(
                 [
                   %{"id" => @uuid_a, "value" => "First copy"},
                   %{"id" => @uuid_a, "value" => "Second copy"}
                 ],
                 @existing_uuid,
                 &ItemIdentity.value_key/1
               )
    end

    test "rejects a malformed echoed id" do
      assert {:error, {:invalid_id, "not-a-uuid"}} =
               ItemIdentity.reconcile(
                 [%{"id" => "not-a-uuid", "value" => "Bad"}],
                 @existing_uuid,
                 &ItemIdentity.value_key/1
               )
    end

    test "strip_ids/1 makes appended items unconditionally new" do
      assert [%{"value" => "Copied"}, %{value: "Also copied"}] =
               ItemIdentity.strip_ids([
                 %{"id" => @uuid_a, "value" => "Copied"},
                 %{id: @uuid_b, value: "Also copied"}
               ])
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

  describe "reconcile_proposed/4 for upstream-minted ids (plan apply)" do
    @existing_minted [
      %{"id" => @uuid_a, "value" => "Keep me"},
      %{"id" => @uuid_b, "value" => "Replace me"}
    ]
    @minted "123e4567-e89b-12d3-a456-426614174111"
    @minted_other "123e4567-e89b-12d3-a456-426614174222"

    test "an unchanged value adopts its existing id, dropping the minted one" do
      assert {:ok, [%{"id" => @uuid_a, "value" => "Keep me"}]} =
               ItemIdentity.reconcile_proposed(
                 [%{"id" => @minted, "value" => "Keep me"}],
                 @existing_minted,
                 &ItemIdentity.value_key/1
               )
    end

    test "genuinely new content keeps its minted id" do
      assert {:ok,
              [
                %{"id" => @uuid_a, "value" => "Keep me"},
                %{"id" => @minted, "value" => "Brand new"}
              ]} =
               ItemIdentity.reconcile_proposed(
                 [
                   %{"id" => @minted_other, "value" => "Keep me"},
                   %{"id" => @minted, "value" => "Brand new"}
                 ],
                 @existing_minted,
                 &ItemIdentity.value_key/1
               )
    end

    test "an id owned by the destination field is honored as an echo" do
      assert {:ok, [%{"id" => @uuid_b, "value" => "Edited in place"}]} =
               ItemIdentity.reconcile_proposed(
                 [%{"id" => @uuid_b, "value" => "Edited in place"}],
                 @existing_minted,
                 &ItemIdentity.value_key/1
               )
    end

    test "rejects an id listed in reject_ids as foreign" do
      assert {:error, {:foreign_id, @uuid_foreign}} =
               ItemIdentity.reconcile_proposed(
                 [%{"id" => @uuid_foreign, "value" => "Hijack"}],
                 @existing_minted,
                 &ItemIdentity.value_key/1,
                 reject_ids: MapSet.new([@uuid_foreign])
               )
    end

    test "rejects duplicate and malformed ids" do
      assert {:error, {:duplicate_id, @minted}} =
               ItemIdentity.reconcile_proposed(
                 [
                   %{"id" => @minted, "value" => "One"},
                   %{"id" => @minted, "value" => "Two"}
                 ],
                 @existing_minted,
                 &ItemIdentity.value_key/1
               )

      assert {:error, {:invalid_id, "nope"}} =
               ItemIdentity.reconcile_proposed(
                 [%{"id" => "nope", "value" => "Bad"}],
                 @existing_minted,
                 &ItemIdentity.value_key/1
               )
    end

    test "id-less values still rehydrate by exact value" do
      assert {:ok, [%{"id" => @uuid_a, "value" => "Keep me"}, %{"value" => "New"}]} =
               ItemIdentity.reconcile_proposed(
                 ["Keep me", %{"value" => "New"}],
                 @existing_minted,
                 &ItemIdentity.value_key/1
               )
    end
  end

  describe "reconcile_appended/3 for plan add operations" do
    test "keeps minted ids on appended items" do
      items = [%{"id" => @minted, "value" => "Appended"}]
      assert {:ok, ^items} = ItemIdentity.reconcile_appended(items, @existing_minted)
    end

    test "rejects an id the destination field already owns" do
      assert {:error, {:duplicate_id, @uuid_a}} =
               ItemIdentity.reconcile_appended(
                 [%{"id" => @uuid_a, "value" => "Shadow"}],
                 @existing_minted
               )
    end

    test "rejects duplicate, malformed, and provably foreign ids" do
      assert {:error, {:duplicate_id, @minted}} =
               ItemIdentity.reconcile_appended(
                 [%{"id" => @minted, "value" => "One"}, %{"id" => @minted, "value" => "Two"}],
                 @existing_minted
               )

      assert {:error, {:invalid_id, "nope"}} =
               ItemIdentity.reconcile_appended([%{"id" => "nope", "value" => "Bad"}], [])

      assert {:error, {:foreign_id, @uuid_foreign}} =
               ItemIdentity.reconcile_appended(
                 [%{"id" => @uuid_foreign, "value" => "Hijack"}],
                 @existing_minted,
                 reject_ids: MapSet.new([@uuid_foreign])
               )
    end
  end
end
