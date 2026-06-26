# 31. AI Provenance

Date: 2026-06-24

## Status

Accepted

## Context

Meadow now applies AI to production metadata: assisted descriptive metadata,
generated transcriptions, and agent-driven plan changes. Until now the only
record that AI had touched a value was a free-text note appended to a work
(`"Some metadata created with the assistance of AI (model) on YYYY-MM-DD"`).
That note cannot be queried, cannot say *which* field changed, carries no link
back to the source items used as evidence, records no model/prompt/cost detail,
and cannot be exported to any preservation or content-provenance standard.

Three external standards bear on what we are obligated to capture:

- **[PREMIS 3.0][premis]** (Library of Congress preservation metadata) models the
  lifecycle of a digital object as **Objects**, **Events** (an audit trail of
  actions an Agent performs on an Object), **Agents** (people, organizations,
  software), and **Rights**. This is the vocabulary preservation systems already
  speak, and the model our repository data should ultimately serialize into.
- **[C2PA / Content Credentials][c2pa]** describes provenance as a signed **manifest**
  containing **assertions** (including `c2pa.actions` and AI-disclosure
  assertions keyed to the IPTC `digitalSourceType` vocabulary) wrapped in a
  **claim**, with prior assets carried as **ingredients**. This is the emerging
  standard for asset-embedded, cryptographically verifiable AI disclosure.
- **[The UVA Archival AI Protocol v1.1][uva]** ("no access without control") requires
  item-level provenance and attribution for any AI use of archival material. Its
  Appendix B sets a minimum citation/logging standard: for every AI-assisted
  output, record the source item and collection IDs, holding organization,
  pointer, and access link, plus an interaction log (date, system + version,
  user category, query/input hash, retrieved items, retention policy).

These three are different projections of the same underlying facts: what an
AI did, to what, using which sources, on whose authority, and how reversibly.
Encoding any one standard's serialization directly into our schema would lock us
to that standard and force a migration when the next one matters. We do not
today mint C2PA manifests or emit PREMIS XML, and we should not pretend to; but
we must capture enough structured evidence now that we *can* project into all
three later without re-instrumenting every AI workflow.

## Decision

Introduce a canonical, standard-neutral AI provenance model under
`Meadow.AI.Provenance`, persisted in dedicated tables (`ai_activities`,
`ai_activity_sources`, `ai_activity_targets`, `ai_activity_events`, `ai_agents`,
`ai_activity_event_agents`) rather than in metadata notes.

The model is shaped around the entities the three standards share:

- An **Activity** is one AI run (system, model, prompt + hash, input/output +
  hashes, cost, timing, initiator). It carries the UVA classification fields
  (`ai_use_type`, `access_mode`, `reversibility`, `user_category`,
  `retention_policy`), defaulting to `retrieval_based` / `reversible` so we stay
  on the permitted side of the protocol's core rule by construction.
- **Sources** are the archival items used as evidence, capturing exactly the
  Appendix B citation fields (collection ID/title, item ID, pointer, holding
  organization, access link, restricted flag) alongside PREMIS object identity
  and fixity.
- **Targets** are the specific fields an activity proposes to change
  (`field_path`, operation, before/after snapshots, `origin`).
- **Events** are the audit trail on a target (proposed, applied, reviewed,
  human-edited, human-attested, deleted), each linkable to **Agents** (human or
  software) by role.

Human mediation of an AI value is itself part of the audit trail, and we record
it as **explicitly chosen actions, never inferred from string comparison**. An
ordinary edit of an AI value flips the target to `ai_assisted_human_modified`
("AI + human edited") and appends a `human_edited` event; clearing it records a
deletion. Separately, a cataloger may **attest** that the live value is now
human-authored even though AI proposed it earlier — for example re-entering a
title from the original catalog record. That is a distinct, explicit path
(`human_attested_after_ai` origin, `human_attested` event) that **appends** to
the AI history rather than rewriting or deleting it: the original AI generation
remains, and the attestation captures actor, timestamp, before/after values, and
an optional reason. The before and after values may be identical — a same-value
attestation is allowed and recorded transparently, so the model can claim "this
value had prior AI provenance and a human later took responsibility for it"
without ever claiming the value was independently human-authored or laundering
the AI badge away.

Persist the standard-specific attributes as **annotations on the canonical
records, not as the storage format**: PREMIS object categories/identifiers and
event types; C2PA action labels, assertion labels, `digitalSourceType` URIs,
human-oversight level, ingredient relationships, and manifest/claim/validation
placeholders. Derive these at write time from the canonical operation (for
example `add` to `c2pa.created`, `replace` to `c2pa.edited`, `delete` to
`c2pa.removed`; overwriting a prior human value selects `algorithmicallyEnhanced`
rather than `trainedAlgorithmicMedia`) so workflows record intent once and the
mappings stay in one place.

Expose the three standards as **read-only export projections**, not as the
system of record:

- `Export.PREMIS`: entity-shaped JSON (Objects/Events/Agents/Rights), explicitly
  not XML/RDF yet, so dc-api-v2 can publish JSON first.
- `Export.UVA`: Appendix B citation + interaction-log evidence, with a computed
  `citation_completeness` signal.
- `Export.C2PAReadiness`: a *readiness* report (does each activity/target carry
  the fields a future manifest would need?), explicitly **not** a manifest and
  with no signing.

Link canonical activities back into the existing domain via nullable
`ai_activity_id` foreign keys on `plan_changes` and `file_set_annotations`
(`on_delete: :nilify_all`), and provide a one-time migration
(`Provenance.LegacyNotes`, with a `mix` task and dry-run) that parses the old
free-text AI notes into canonical records.

## Consequences

AI provenance becomes queryable, item-level, and exportable into PREMIS, the UVA
protocol's Appendix B, and a C2PA-readiness view from a single canonical source,
which positions Meadow to satisfy "no access without control" without
re-instrumenting AI workflows when any one standard's serialization is required.

The canonical schema is the contract; the standards are projections. Adopting a
new standard, or upgrading PREMIS to XML/RDF or C2PA to real signed manifests,
is an additive export module plus (where needed) annotation fields, not a
remodel. The cost is that the schema is deliberately wider than any single
standard requires: it carries PREMIS, C2PA, and UVA annotation columns
side by side, and the standard-to-canonical mappings (operation to C2PA action,
origin to oversight level, IPTC source type selection) must be maintained as the
standards evolve.

C2PA support is readiness only: we report whether an activity *could* be
expressed as a manifest, but mint and sign nothing. Consumers must not treat the
C2PA fields as verifiable credentials until real manifest generation and signing
land.

Every AI-assisted change must now create provenance records, so AI workflows
(metadata apply, transcription, planner/agent plan changes) take on a write
dependency they did not have before. Legacy AI notes are superseded by canonical
records via the `LegacyNotes` migration; the human-readable notes can remain for
display but are no longer the source of truth.

## References

- [The University of Virginia Archival AI Protocol, v1.1][uva]
- [PREMIS Data Dictionary for Preservation Metadata, Version 3.0][premis]
- [C2PA (Coalition for Content Provenance and Authenticity) Specifications][c2pa]

[uva]: https://doi.org/10.18130/5dqf-9w86
[premis]: https://www.loc.gov/standards/premis/v3/
[c2pa]: https://spec.c2pa.org/specifications/specifications/2.4/specs/C2PA_Specification.html
