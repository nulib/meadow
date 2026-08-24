defmodule Meadow.AI.NoteCleanupTest do
  use Meadow.DataCase

  alias Meadow.AI.NoteCleanup
  alias Meadow.Data.Works

  @ai_note %{
    note: "Some metadata created with the assistance of AI (test-model) on 2026-06-24",
    type: %{id: "LOCAL_NOTE", scheme: "note_type"}
  }

  @curator_note %{
    note: "Curator wrote this.",
    type: %{id: "GENERAL_NOTE", scheme: "note_type"}
  }

  @transcription_note %{
    note: "Transcription generated for page 1 by AI (test-model) on 2026-06-24",
    type: %{id: "LOCAL_NOTE", scheme: "note_type"}
  }

  describe "candidates/0" do
    test "finds a work with only an AI note" do
      work = work_fixture(%{descriptive_metadata: %{title: "AI only", notes: [@ai_note]}})

      assert NoteCleanup.candidates() == %{count: 1, work_ids: [work.id]}
    end

    test "does not select a work with no notes" do
      work_fixture(%{descriptive_metadata: %{title: "No notes"}})

      assert %{count: 0, work_ids: []} = NoteCleanup.candidates()
    end

    test "does not select a work whose only note is a transcription note" do
      work_fixture(%{
        descriptive_metadata: %{title: "Transcription only", notes: [@transcription_note]}
      })

      assert %{count: 0, work_ids: []} = NoteCleanup.candidates()
    end

    test "does not select a work whose only note is a curator note" do
      work_fixture(%{descriptive_metadata: %{title: "Curator only", notes: [@curator_note]}})

      assert %{count: 0, work_ids: []} = NoteCleanup.candidates()
    end
  end

  describe "run/1" do
    test "removes a work's only note, leaving notes empty" do
      work = work_fixture(%{descriptive_metadata: %{title: "AI only", notes: [@ai_note]}})

      assert %{works_updated: 1, notes_removed: 1, dry_run: false} =
               NoteCleanup.run(dry_run: false)

      assert Works.get_work!(work.id).descriptive_metadata.notes == []
    end

    test "removes the AI note but keeps a curator note on the same work" do
      work =
        work_fixture(%{
          descriptive_metadata: %{title: "Mixed", notes: [@ai_note, @curator_note]}
        })

      assert %{works_updated: 1, notes_removed: 1} = NoteCleanup.run(dry_run: false)

      assert [%{note: "Curator wrote this.", type: %{id: "GENERAL_NOTE"}}] =
               Works.get_work!(work.id).descriptive_metadata.notes
    end

    test "does not touch a work whose only note is a transcription note" do
      work =
        work_fixture(%{
          descriptive_metadata: %{title: "Transcription only", notes: [@transcription_note]}
        })

      assert %{works_updated: 0, notes_removed: 0} = NoteCleanup.run(dry_run: false)

      assert [%{note: note_text, type: %{id: "LOCAL_NOTE"}}] =
               Works.get_work!(work.id).descriptive_metadata.notes

      assert note_text =~ "Transcription generated"
    end

    test "removes only the AI note when it appears alongside a transcription note" do
      work =
        work_fixture(%{
          descriptive_metadata: %{title: "Mixed AI", notes: [@ai_note, @transcription_note]}
        })

      assert %{works_updated: 1, notes_removed: 1} = NoteCleanup.run(dry_run: false)

      assert [%{note: note_text, type: %{id: "LOCAL_NOTE"}}] =
               Works.get_work!(work.id).descriptive_metadata.notes

      assert note_text =~ "Transcription generated"
    end

    test "dry_run: true (the default) changes nothing" do
      work = work_fixture(%{descriptive_metadata: %{title: "AI only", notes: [@ai_note]}})

      assert %{works_updated: 1, notes_removed: 1, dry_run: true} = NoteCleanup.run()

      assert [%{type: %{id: "LOCAL_NOTE"}}] = Works.get_work!(work.id).descriptive_metadata.notes
    end

    test "is idempotent: running twice finds nothing left the second time" do
      work_fixture(%{descriptive_metadata: %{title: "AI only", notes: [@ai_note]}})

      assert %{works_updated: 1} = NoteCleanup.run(dry_run: false)
      assert %{works_updated: 0, notes_removed: 0} = NoteCleanup.run(dry_run: false)
    end
  end
end
