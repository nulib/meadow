defmodule Meadow.AI.NoteCleanup do
  @moduledoc """
  One-off cleanup for the free-text AI metadata disclosure note previously
  written by `MeadowWeb.MCP.Tools.ApplyWorkMetadata` and
  `MeadowWeb.MCP.Tools.UpdatePlanChange` (`"Some metadata created with the
  assistance of AI (model) on YYYY-MM-DD"`). Those tools no longer write this
  note — the disclosure has moved to the front end, driven by
  `Meadow.AI.Provenance` — so this module removes the historical ones from
  works that still carry them.

  Deliberately does not touch the differently-worded transcription note
  written by `Meadow.Data.FileSets.add_transcription_note/1`
  (`"Transcription generated for <label> by AI..."`). The two note texts share
  no prefix, so the matcher below can't confuse them; whether transcriptions
  get an equivalent cleanup is a separate, not-yet-decided question.

  Intended to be run once, by hand, from Livebook or `iex -S mix`, after the
  code change that stops writing the note has deployed — it is not wired into
  any release task or scheduled job. Meadow ships as a release rather than an
  escript, so a plain module is used here instead of a `Mix.Task`: both
  existing maintenance tasks (`Mix.Tasks.Meadow.BackfillAnnotationContent`,
  `Mix.Tasks.Meadow.InitializeDerivatives`) call `Mix.Task.run("app.start")`,
  which is the wrong call once Livebook has already started the application.

  Usage:

      Meadow.AI.NoteCleanup.audit()        # read distinct note texts first
      Meadow.AI.NoteCleanup.candidates()   # how many works would be touched
      Meadow.AI.NoteCleanup.run()          # dry run by default
      Meadow.AI.NoteCleanup.run(dry_run: false)

  `run/1` goes through `Meadow.Data.Works.update_work/2` per work rather than a
  bulk `UPDATE`, so each change emits its usual WAL event and the public search
  index self-corrects with no separate reindex step. The candidate query
  excludes works that no longer match, so a re-run after a partial failure
  only touches what's left.
  """

  import Ecto.Query, warn: false

  alias Meadow.Data.Schemas.Work
  alias Meadow.Data.Works
  alias Meadow.Repo

  require Logger

  # Mirrors the prefix `MeadowWeb.MCP.Tools.ApplyWorkMetadata` and
  # `MeadowWeb.MCP.Tools.UpdatePlanChange` used to write.
  @ai_note_prefix "Some metadata created with the assistance of AI"
  @note_type_id "LOCAL_NOTE"
  @default_batch_size 100

  @doc """
  Read-only. Groups every note whose text mentions "AI" — deliberately broader
  than the exact matcher `run/1` uses — with an occurrence count, so wording
  variants can be reviewed before anything is deleted. The note text was at
  one point produced by the LLM itself from a prompt instruction rather than a
  hardcoded string, so production wording may not exactly match
  `@ai_note_prefix`. Run this first, before `candidates/0` or `run/1`.
  """
  def audit do
    %Postgrex.Result{rows: rows} =
      Repo.query!("""
      SELECT n->>'note' AS note_text, n->'type'->>'id' AS type_id, count(*) AS occurrences
      FROM works w, jsonb_array_elements(w.descriptive_metadata->'notes') n
      WHERE jsonb_typeof(w.descriptive_metadata->'notes') = 'array'
        AND n->>'note' ILIKE '%AI%'
      GROUP BY 1, 2
      ORDER BY 3 DESC
      """)

    Enum.map(rows, fn [note_text, type_id, occurrences] ->
      %{note_text: note_text, type_id: type_id, occurrences: occurrences}
    end)
  end

  @doc """
  Read-only. The ids of works `run/1` would currently modify, and how many.
  """
  def candidates do
    ids = candidate_query() |> select([w], w.id) |> Repo.all()
    %{count: length(ids), work_ids: ids}
  end

  @doc """
  Remove the AI metadata disclosure note from every work that has one,
  preserving every other note on the work. Defaults to `dry_run: true` so a
  bare call is always safe; pass `dry_run: false` to actually write.

  Options:
    * `:dry_run` — when true (the default), counts what would change without
      writing anything.
    * `:batch_size` — how many works to load and update per chunk (default
      #{@default_batch_size}). Chunking (rather than one long transaction)
      keeps the job interruptible: a failure partway through leaves already-
      processed works cleaned, and the candidate query excludes them from the
      next run.
  """
  def run(opts \\ []) do
    dry_run = Keyword.get(opts, :dry_run, true)
    batch_size = Keyword.get(opts, :batch_size, @default_batch_size)

    ids = candidate_query() |> select([w], w.id) |> Repo.all()
    total = length(ids)

    Logger.info(
      "Meadow.AI.NoteCleanup: #{total} candidate work(s) found" <>
        if(dry_run, do: " (dry run, no changes will be written)", else: "")
    )

    {works_updated, notes_removed} =
      ids
      |> Enum.chunk_every(batch_size)
      |> Enum.with_index(1)
      |> Enum.reduce({0, 0}, fn {batch, batch_number}, {updated_acc, removed_acc} ->
        {updated, removed} = process_batch(batch, dry_run)

        Logger.info(
          "Meadow.AI.NoteCleanup: batch #{batch_number} — " <>
            "#{updated_acc + updated}/#{total} works updated so far"
        )

        {updated_acc + updated, removed_acc + removed}
      end)

    %{works_updated: works_updated, notes_removed: notes_removed, dry_run: dry_run}
  end

  defp candidate_query do
    from(w in Work,
      where:
        fragment(
          "jsonb_typeof(?->'notes') = 'array' AND EXISTS (\
             SELECT 1 FROM jsonb_array_elements(?->'notes') n \
             WHERE n->>'note' LIKE ? AND n->'type'->>'id' = ?\
           )",
          w.descriptive_metadata,
          w.descriptive_metadata,
          ^"#{@ai_note_prefix}%",
          ^@note_type_id
        )
    )
  end

  defp process_batch(ids, dry_run) do
    ids
    |> Enum.map(&Works.get_work!/1)
    |> Enum.reduce({0, 0}, fn work, {updated_acc, removed_acc} ->
      case strip_ai_notes(work) do
        :unchanged ->
          {updated_acc, removed_acc}

        {:changed, kept_notes, removed_count} ->
          unless dry_run, do: update_notes!(work, kept_notes)
          {updated_acc + 1, removed_acc + removed_count}
      end
    end)
  end

  defp strip_ai_notes(%Work{descriptive_metadata: %{notes: notes}}) do
    case Enum.split_with(notes, &ai_note?/1) do
      {[], _kept} -> :unchanged
      {removed, kept} -> {:changed, Enum.map(kept, &note_to_map/1), length(removed)}
    end
  end

  defp ai_note?(%{note: note, type: %{id: @note_type_id}}) when is_binary(note) do
    String.starts_with?(note, @ai_note_prefix)
  end

  defp ai_note?(_note), do: false

  # Existing notes arrive as `%NoteEntry{}` structs with an already-loaded
  # (plain map) `type`; strip the struct wrapper so the retained list round-
  # trips through `Works.update_work/2` the same way `add_transcription_note/1`
  # does for the same reason.
  defp note_to_map(%_{} = struct), do: Map.from_struct(struct)
  defp note_to_map(map) when is_map(map), do: map

  defp update_notes!(work, kept_notes) do
    case Works.update_work(work, %{descriptive_metadata: %{notes: kept_notes}}) do
      {:ok, _updated_work} ->
        :ok

      {:error, changeset} ->
        Logger.warning(
          "Meadow.AI.NoteCleanup: failed to update work #{work.id}: #{inspect(changeset.errors)}"
        )

        :error
    end
  end
end
