# 32. Remove the AI disclosure notes

Date: 2026-08-24

## Status

Accepted

## Context

[31. AI Provenance](0031-ai-provenance.md) introduced a canonical provenance
model (`Meadow.AI.Provenance`) but deliberately kept two pre-existing free-text
disclosure notes alongside it, for human readability and continuity:

- A descriptive-metadata note (`"Some metadata created with the assistance of
  AI (model) on YYYY-MM-DD"`), written by `MeadowWeb.MCP.Tools.ApplyWorkMetadata`
  and `MeadowWeb.MCP.Tools.UpdatePlanChange`.
- A transcription note (`"Transcription generated for <label> by AI (model) on
  YYYY-MM-DD"`), written by `Meadow.Data.FileSets` whenever an AI transcription
  completes.

Both notes have the same three problems in practice:

- Their wording is baked into every record they touch. Changing the message —
  contact address, clearer language, legal review — means finding and
  rewriting that text across every affected work, rather than changing one
  template in the system that displays it.
- Neither is usable as data. Each is free text sitting among genuine curatorial
  notes, so it cannot be searched, counted, styled, or placed consistently on
  a page; a caller has to string-match a prefix to distinguish it from other
  notes at all (see `same_ai_note?/2`, since removed from
  `MeadowWeb.MCP.Tools.UpdatePlanChange`).
- Both accumulate. A new note was written on every AI touch, dated and stamped
  with the model in use; `MeadowWeb.MCP.Tools.ApplyWorkMetadata` additionally
  passed a single-element `notes:` list into an `embeds_many(..., on_replace:
  :delete)` field, which silently discarded any existing curator-authored
  notes on the work.

The canonical provenance model this ADR keeps already carries everything both
notes said and more — per-field origin, model, timestamp, reviewer — and is
already indexed per work (`ai_provenance` in the v2 search index, per
descendant `FileSetAnnotation` in the v2 file set index) and served publicly
through the existing API. Both notes were redundant with a better source of
truth from the moment 0031 landed.

## Decision

Stop writing both free-text notes. `MeadowWeb.MCP.Tools.ApplyWorkMetadata` and
`MeadowWeb.MCP.Tools.UpdatePlanChange` no longer inject the descriptive-metadata
note; `Meadow.Data.FileSets` no longer injects the transcription note. Public
disclosure moves to the front end, driven by a new `ai_involved` field added to
the work search index (`Meadow.AI.Provenance.ai_involvement/2`), computed from
the same provenance targets the notes used to summarize secondhand. A single
cleanup module, `Meadow.AI.NoteCleanup`, removes both note kinds from works
that already carry them — they share note type `LOCAL_NOTE` and are
distinguished only by prefix, so one module covers both.

`ai_involved` is an object rather than a bare boolean, so the one field says
*which kind* of AI involvement a work carries instead of collapsing both into
one signal a caller can't take apart:

```json
"ai_involved": {
  "descriptive_metadata": true,
  "file_set_annotations": false
}
```

`descriptive_metadata` reflects applied AI provenance on the work's own fields
(`target_type == "Work"`); `file_set_annotations` reflects an applied
AI-generated annotation — a transcription today — on one of the work's file
sets (`target_type == "FileSetAnnotation"`, scoped to this work via the
target's activity). Both are computed from the one `work_summary/1` call
index-time callers already make, so this costs no extra query.

This reverses only the note-retention clause of 0031; the canonical provenance
model, its schema, and its export projections are unchanged and remain the
system of record.

## Consequences

Public disclosure of AI-assisted descriptive metadata and AI transcriptions
now depends on the front end reading `ai_involved` (and, for detail,
`ai_provenance`) rather than on a note being present in the record. Consumers
that read notes directly — IIIF manifest metadata, CSV exports — no longer see
an AI disclosure for metadata or transcriptions generated after this change
ships, until and unless `ai_involved` is also surfaced through those paths.

Existing notes are not removed by this change alone; `Meadow.AI.NoteCleanup`
must be run by hand against each environment afterward. Until that cleanup
runs, works touched before this change keep their old dated notes displayed
alongside curator notes, while works touched after it do not gain new ones.

`ai_involved` changing shape from a boolean to an object is a search mapping
change (object properties, not `"enabled": false`, so both flags stay
filterable) and requires a full reindex of the work index — a rolling
document-by-document update cannot change a field's mapped type in place.
