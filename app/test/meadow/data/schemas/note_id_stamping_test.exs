defmodule Meadow.Data.Schemas.NoteIdStampingTest do
  @moduledoc """
  Notes/related URLs applied through the direct-jsonb path (plans, batch updates)
  must be stamped with a primary-key id, or the embed is stored with a nil id and
  the next changeset edit of the work fails with "missing primary key value".
  """
  use Meadow.DataCase

  alias Meadow.Data.Schemas.WorkDescriptiveMetadata
  alias Meadow.Data.Works
  alias Meadow.Repo

  @existing_id "123e4567-e89b-12d3-a456-426614174000"

  test "jsonb_value_entries stamps ids on notes and related_url" do
    normalized =
      WorkDescriptiveMetadata.jsonb_value_entries(%{
        "notes" => [%{"note" => "A note", "type" => %{"id" => "LOCAL_NOTE"}}],
        "related_url" => [%{"url" => "http://example.com"}]
      })

    # Stamped in the entry's own key style, so string-keyed input yields a
    # uniformly string-keyed map for the jsonb write.
    [note] = normalized["notes"]
    [url] = normalized["related_url"]

    assert note["note"] == "A note"
    assert url["url"] == "http://example.com"
    assert {:ok, _} = Ecto.UUID.cast(note["id"])
    assert {:ok, _} = Ecto.UUID.cast(url["id"])
  end

  test "keeps an existing note id (idempotent)" do
    normalized =
      WorkDescriptiveMetadata.jsonb_value_entries(%{
        "notes" => [
          %{"id" => @existing_id, "note" => "A note", "type" => %{"id" => "LOCAL_NOTE"}}
        ]
      })

    assert [%{"id" => @existing_id}] = normalized["notes"]
  end

  test "a work with a jsonb-applied note remains editable through the changeset" do
    work = work_fixture()

    # Simulate the plan/batch apply path: write a note straight to jsonb, stamped
    # with an id the way the normalizer now does.
    dm =
      Repo.one(
        from(w in "works",
          where: w.id == type(^work.id, Ecto.UUID),
          select: w.descriptive_metadata
        )
      )

    dm =
      Map.put(
        dm,
        "notes",
        WorkDescriptiveMetadata.jsonb_value_entries(%{
          "notes" => [%{"note" => "AI note", "type" => %{"id" => "LOCAL_NOTE"}}]
        })["notes"]
      )

    Repo.query!("UPDATE works SET descriptive_metadata = $1 WHERE id = $2", [
      dm,
      Ecto.UUID.dump!(work.id)
    ])

    # Editing another field re-casts the notes embed; with a nil-id note this would
    # raise "missing primary key value".
    work = Works.get_work!(work.id)

    assert {:ok, _updated} =
             Works.update_work(work, %{descriptive_metadata: %{title: "New title"}})
  end
end
