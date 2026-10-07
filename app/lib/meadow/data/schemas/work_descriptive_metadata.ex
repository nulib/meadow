defmodule Meadow.Data.Schemas.WorkDescriptiveMetadata do
  @moduledoc """
  Descriptive metadata for a Work.

  Everything except controlled terms, notes and related URLs lives on the
  `work_descriptive_metadata` row (one per work, keyed by `work_id`): scalars
  and coded terms as columns, repeating free text and EDTF dates as `text[]`,
  and places as an embedded jsonb list. Controlled terms
  (`work_controlled_entries`), notes (`work_notes`) and related URLs
  (`work_related_urls`) are child rows, because each is either queried
  relationally or carries a foreign key to `coded_terms`.

  Fields are declared in CSV export header order; see
  `Meadow.Data.Schemas.MetadataSchema` for what each kind generates.
  """

  use Meadow.Data.Schemas.MetadataSchema,
    table: "work_descriptive_metadata",
    section: "descriptive"

  alias Meadow.Data.Schemas.{NoteEntry, RelatedURLEntry}

  metadata do
    values(:abstract)
    values(:alternate_title)
    values(:box_name)
    values(:box_number)
    values(:caption)
    values(:catalog_key)
    values(:citation)
    values(:cultural_context)
    values(:description)
    values(:folder_name)
    values(:folder_number)
    values(:identifier)
    values(:keywords)
    values(:legacy_identifier)

    string(:terms_of_use)

    values(:physical_description_material)
    values(:physical_description_size)
    values(:provenance)
    values(:publisher)
    values(:related_material)
    values(:rights_holder)
    values(:scope_and_contents)
    values(:series)
    values(:source)
    values(:table_of_contents)

    string(:title)

    places(:nav_place)

    coded(:license)
    coded(:rights_statement)

    controlled(:contributor, role_required: true)
    controlled(:creator)
    controlled(:genre)
    controlled(:language)
    controlled(:location)
    controlled(:style_period)
    controlled(:subject, role_required: true)
    controlled(:technique)

    dates(:date_created)

    entries(:notes, NoteEntry)
    entries(:related_url, RelatedURLEntry)
  end
end
