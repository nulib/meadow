# 32. Relational Metadata Tables

Date: 2026-08-20

## Status

Accepted

## Context

Since the first migration, Meadow has stored most domain metadata in
PostgreSQL jsonb columns modeled as Ecto embeds: `works.descriptive_metadata`
and `works.administrative_metadata` (scalar fields, string arrays, coded terms,
controlled-term entries, notes, related URLs, EDTF dates and places all in one
document), `file_sets.core_metadata`, `structural_metadata`,
`extracted_metadata` and `derivatives`, the coded-term columns
(`works.visibility`, `file_sets.role`, ...), ingest sheet row fields and
errors, and the plan change operation maps.

That shape was convenient to write but increasingly expensive to query and to
keep correct:

- Finding works by controlled term needed a trigger-maintained projection
  table (`work_terms`) that shredded the jsonb on every write.
- Batch updates and plan-change application went through two plpgsql
  functions (`replace_controlled_value`, `merge_jsonb_values`) that rewrote
  whole documents with no validation, and CSV metadata updates issued a raw
  `COPY` into a temp table followed by `UPDATE works SET ...`.
- Filters on coded terms (`visibility -> 'id' = ?`, `role @> ?::jsonb`) could
  not use ordinary indexes or foreign keys, and nothing in the database
  guaranteed that a stored code existed in `coded_terms`.
- Items in repeating fields had no identity. Giving them stable ids for
  item-level AI provenance (ADR 31) required inventing an identity contract on
  top of jsonb arrays and a backfill that rewrote every document (the
  unmerged pull request #5619).

Every one of those workarounds reimplements something a relational schema
provides natively: rows with primary keys, foreign keys, indexes, constraints
and set-based updates.

## Decision

Replace the jsonb metadata columns with relational tables and model them as
ordinary Ecto schemas and associations. The Elixir struct API stays the same
(`work.descriptive_metadata.subject`, `work.visibility.label`,
`file_set.core_metadata.location`), so the GraphQL layer, the search index
encoders and the CSV code keep reading metadata the way they always have; only
the storage and the write paths change.

Concretely, for works:

- `work_descriptive_metadata` and `work_administrative_metadata` hold the
  scalar and coded fields, one row per work keyed by `work_id`.
- Repeating fields are child rows with a uuid `id` and a `position`:
  `work_metadata_values` (all repeating free text, with `section` and `field`
  columns), `work_controlled_entries` (term URI plus optional role),
  `work_notes`, `work_related_urls`, `work_dates_created` and
  `work_nav_places`.
- Coded terms are stored as their text id. Each coded column is paired with a
  generated `*_scheme` column so the pair carries a real composite foreign
  key to `coded_terms (id, scheme)`; `Meadow.Data.Types.CodedTerm` is an
  `Ecto.ParameterizedType` that takes the scheme from the field declaration
  and still loads `%{id, scheme, label}`.
- In Ecto, `embeds_one` becomes `has_one` and each repeating field is a
  filtered `has_many` on the shared child table (`where:` for reads,
  `defaults:` so rows built by `cast_assoc` are stamped with the field,
  `preload_order: [asc: :position]`, `on_replace: :delete`).
  `Meadow.Data.Schemas.MultiValued` normalizes incoming lists (bare strings
  become `{value}` params), reattaches ids to unchanged items by exact natural
  key so re-sending a list never remints ids, rejects foreign or duplicate
  ids, and hands the list to `cast_assoc`, which does the insert, update and
  delete diffing. Position uniqueness is a deferrable constraint because a
  reorder rewrites positions inside one transaction.
- Batch updates and plan-change application use
  `Meadow.Data.Works.MetadataWriter`, which validates values through the same
  entry changesets and then applies them with `insert_all`, `delete_all` and
  `update_all`. The CSV metadata update applies each row through
  `Work.update_changeset/2`. The plpgsql functions, the `work_terms` table and
  its triggers are dropped.
- `WorkDescriptiveMetadata` and `WorkAdministrativeMetadata` are declared with
  `Meadow.Data.Schemas.MetadataSchema`: each field is listed once with its kind
  (`string`, `coded`, `values`, `controlled`, `entries`) and the Ecto schema,
  the changeset and a `__metadata__/1,2` reflection function are generated
  from that list. Code that needs to classify fields (the planner, the batch
  writer, the MCP tools) asks the schema instead of keeping its own lists.
- `Work.metadata_preloads/0` is the single preload list for the metadata rows;
  `Meadow.Data.Works` applies it on every read, `Work.changeset/2` preloads
  anything still missing before casting, and the search indexer and dataloader
  include it. The metadata tables are added to the WAL publication so a change
  to any metadata row reindexes its work.
- GraphQL exposes repeating free-text values as `{ id, value }` objects and
  accepts an optional `id` on every repeating input; notes, related URLs,
  dates and controlled entries gain an `id` as well. The search index and the
  CSV export keep their flat public shapes.

The same approach applies, table by table, to file set metadata, ingest sheet
rows and states, and plan change operations.

The cutover is one-shot and forward-only: each migration creates the tables,
checks referential integrity up front (unknown coded terms fail the migration
with a list of offenders rather than being dropped), backfills from the jsonb
in SQL with `jsonb_array_elements ... WITH ORDINALITY` for positions, verifies
row counts, and wires the publication. The original jsonb columns are left in
place until a final cleanup migration removes them.

## Consequences

Metadata becomes queryable with joins and indexes, enforceable with foreign
keys and check constraints, and writable through validated changesets and
set-based Ecto queries. Every repeating item has a stable uuid, so the goals
of the unmerged item-identity work are met by the primary key, and the
reconciliation heuristics that work needed are unnecessary. Free-text item
provenance continues to be keyed by the item's text until plan change
operations carry their own ids (the relational plan change phase), at which
point the minted operation id can become the value row id.

Reads that touch metadata must preload the associations. A list preload costs
one query per association (about forty per list, independent of list size),
which is acceptable for the staff interface and the indexer's chunks; a
grouped single-query loader remains available as an optimization if a hot path
needs it. A changeset on a work that was fetched without the preloads is
repaired automatically, at the cost of the missing preload queries.

Clients that edit repeating values should echo the `id` they were given;
unchanged values are matched by text either way, but an edited value without
its id is new content. The CSV cell format is unchanged.
