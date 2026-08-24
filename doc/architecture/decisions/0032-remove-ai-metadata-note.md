# 32. Remove the AI metadata disclosure note

Date: 2026-08-24

## Status

Accepted

## Context

[31. AI Provenance](0031-ai-provenance.md) introduced a canonical provenance
model (`Meadow.AI.Provenance`) but deliberately kept the pre-existing
free-text disclosure note (`"Some metadata created with the assistance of AI
(model) on YYYY-MM-DD"`) alongside it, for human readability and continuity.

That note has three problems in practice:

- Its wording is baked into every record it touches. Changing the message —
  contact address, clearer language, legal review — means finding and
  rewriting that text across every affected work, rather than changing one
  template in the system that displays it.
- It is not usable as data. It is free text sitting among genuine curatorial
  notes, so it cannot be searched, counted, styled, or placed consistently on
  a page; a caller has to string-match a prefix to distinguish it from other
  notes at all (see `same_ai_note?/2`, since removed from
  `MeadowWeb.MCP.Tools.UpdatePlanChange`).
- It accumulates. A new note was written on every AI touch, dated and stamped
  with the model in use; `MeadowWeb.MCP.Tools.ApplyWorkMetadata` additionally
  passed a single-element `notes:` list into an `embeds_many(..., on_replace:
  :delete)` field, which silently discarded any existing curator-authored
  notes on the work.

The canonical provenance model this ADR keeps already carries everything the
note said and more — per-field origin, model, timestamp, reviewer — and is
already indexed per work (`ai_provenance` in the v2 search index) and served
publicly through the existing API. The note was redundant with a better
source of truth from the moment 0031 landed.

## Decision

Stop writing the free-text note for AI-assisted descriptive metadata.
`MeadowWeb.MCP.Tools.ApplyWorkMetadata` and `MeadowWeb.MCP.Tools.UpdatePlanChange`
no longer inject it; the public disclosure moves to the front end, driven by a
new `ai_involved` boolean added to the work search index
(`Meadow.AI.Provenance.ai_involved?/2`), computed from the same provenance
targets the note used to summarize secondhand. A one-off cleanup module,
`Meadow.AI.NoteCleanup`, removes the note from works that already carry it.

This reverses only the note-retention clause of 0031; the canonical provenance
model, its schema, and its export projections are unchanged and remain the
system of record.

**Transcriptions are explicitly out of scope.** `Meadow.Data.FileSets`
still writes its own differently-worded note (`"Transcription generated for
<label> by AI..."`) when an AI transcription completes, and `ai_involved` is
scoped to `target_type == "Work"` so it reflects only descriptive-metadata
provenance. Whether transcriptions warrant an equivalent note removal and
front-end indicator is a separate, not-yet-decided question.

## Consequences

Public disclosure of AI-assisted descriptive metadata now depends on the
front end reading `ai_involved` (and, for detail, `ai_provenance`) rather than
on a note being present in the record. Consumers that read notes directly —
IIIF manifest metadata, CSV exports — no longer see an AI disclosure for
metadata generated after this change ships, until and unless `ai_involved` is
also surfaced through those paths.

Existing notes are not removed by this change alone; `Meadow.AI.NoteCleanup`
must be run by hand against each environment afterward. Until that cleanup
runs, works edited before this change keep their old dated notes displayed
alongside curator notes, while works edited after it do not gain new ones.
