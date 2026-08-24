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

Concretely, for works, a child table is created only where one earns its keep:
where it carries a foreign key, or where it is queried relationally. Repeating
fields that are neither become columns on the metadata row — normalizing a
repeating scalar purely to give it row identity buys nothing and costs a
wrapper struct, a preload and a public shape change. Applying that test field
by field:

| Field kind | Storage | Why |
| --- | --- | --- |
| repeating free text (29 fields) | `text[]` column | no foreign key, never joined |
| EDTF dates (`date_created`) | `text[]` of EDTF strings | no foreign key, never joined |
| places (`nav_place`) | embedded jsonb | no foreign key, never joined, and cannot be batch updated or proposed |
| controlled terms (8 fields) | `work_controlled_entries` | queried by term and role; role has a foreign key |
| notes, related URLs | `work_notes`, `work_related_urls` | note type and URL label have foreign keys |
| scalars, coded terms | columns | — |

- `work_descriptive_metadata` and `work_administrative_metadata` hold one row
  per work keyed by `work_id`: scalars and coded terms as columns, repeating
  free text and EDTF dates as `text[]`, places as embedded jsonb.
- `work_controlled_entries`, `work_notes` and `work_related_urls` are child
  rows with a uuid `id` and a `position`.
- A controlled entry's identity is its natural key (`work_id`, `field`,
  `term_id`, `role_id`), enforced by a unique index; the uuid is only a
  technical primary key and is not exposed. `role_scheme` is a generated column
  (`contributor` implies `marc_relator`, `subject` implies `subject_role`), so
  the application never maintains it while the pair still carries a real
  foreign key.
- Derived values are not stored. A coded term's label is resolved from
  `coded_terms` on load, a controlled term's from the term cache, and a date's
  `humanized` rendering is computed by `Meadow.Data.Types.EDTFDate` on load, so
  a change to the humanizer cannot leave stale renderings behind. Plan change
  operations are the exception: they record `term_label` and `role_label` as
  shown to the reviewer at proposal time, because an authority can relabel a
  term afterwards.
- Coded terms are stored as their text id. Each coded column is paired with a
  generated `*_scheme` column so the pair carries a real composite foreign
  key to `coded_terms (id, scheme)`; `Meadow.Data.Types.CodedTerm` is an
  `Ecto.ParameterizedType` that takes the scheme from the field declaration
  and still loads `%{id, scheme, label}`.
- In Ecto, `embeds_one` becomes `has_one`. Controlled fields are filtered
  `has_many` associations on the shared child table (`where:` for reads,
  `defaults:` so rows built by `cast_assoc` are stamped with the field,
  `preload_order: [asc: :position]`, `on_replace: :delete`); notes and related
  URLs have a table each. `Meadow.Data.Schemas.MultiValued` normalizes incoming
  lists, reattaches ids to unchanged items by exact natural key so re-sending a
  list never remints ids or rewrites unchanged rows, rejects foreign or
  duplicate ids, and hands the list to `cast_assoc`, which does the insert,
  update and delete diffing. It now serves ten fields rather than forty-one.
  Position uniqueness is a deferrable constraint because a reorder rewrites
  positions inside one transaction. Array-backed fields need none of this:
  order is the array's own order, and the whole column is rewritten at once.
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
- The GraphQL shape is unchanged from before the cutover: repeating free-text
  values are `[String]`, and controlled entries and dates carry no `id`. Only
  notes and related URLs gain an `id`, which clients echo so that an unrelated
  edit does not rewrite the rows. The search index and the CSV export keep
  their flat public shapes.

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
set-based Ecto queries. Controlled terms in particular are searchable by term,
by term and role, and by term, role and field, all served by one index — the
capability the `work_terms` projection existed to provide.

The Elixir struct API really is unchanged from the jsonb embeds:
`work.descriptive_metadata.abstract` is a list of strings, `date_created` a
list of `%{edtf, humanized}`, `nav_place` a list of place structs. No accessor,
unwrapping helper or public/internal shape distinction is needed, and the
search index encoder, the ARK builder, provenance and the CSV code read
metadata exactly as they did before.

Reads that touch metadata must preload the two metadata rows and the ten child
associations. A list preload costs one query per association, independent of
list size; a grouped single-query loader for the eight controlled fields
remains available if a hot path needs it. A changeset on a work fetched without
the preloads is repaired automatically, at the cost of the missing queries.

Two costs are accepted deliberately:

- Free-text items have no stable id. Item-level provenance (ADR 31) keys them
  by text, which is what it already did, and plan change operations now carry
  their own ids. If per-item identity becomes necessary, it can be added by
  giving the fields back their rows, or by keying provenance to the operation
  id.
- Substring search over an array needs `EXISTS (SELECT 1 FROM unnest(col) v
  WHERE v ILIKE ?)`, which no index serves, or a `pg_trgm` expression index on
  `array_to_string(col, ' ')` — one per searchable field, where a row-per-value
  table would need one index for all of them. This is acceptable because
  free-text search over works is served by the search index, and no query in
  the application does substring matching on these fields.

The CSV cell format and header order are unchanged; header order now derives
from the schema declaration order rather than a hand-maintained list.
