defmodule Meadow.Data.Schemas.WorkDescriptiveMetadata do
  @moduledoc """
  Descriptive metadata for a Work.

  String and coded fields live on the `work_descriptive_metadata` row (one per
  work, keyed by `work_id`). Repeating fields are child rows: free text in
  `work_metadata_values`, controlled terms in `work_controlled_entries`, and
  notes, related URLs, dates and places in their own tables. See
  `Meadow.Data.Schemas.MetadataSchema` for what each kind generates.
  """

  use Meadow.Data.Schemas.MetadataSchema,
    table: "work_descriptive_metadata",
    section: "descriptive"

  alias Meadow.Data.Schemas.{DateCreatedEntry, NavPlaceEntry, NoteEntry, RelatedURLEntry}

  metadata do
    string(:title)
    string(:terms_of_use)

    coded(:license)
    coded(:rights_statement)

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

    controlled(:contributor, role_required: true)
    controlled(:creator)
    controlled(:genre)
    controlled(:language)
    controlled(:location)
    controlled(:style_period)
    controlled(:subject, role_required: true)
    controlled(:technique)

    entries(:date_created, DateCreatedEntry)
    entries(:notes, NoteEntry)
    entries(:related_url, RelatedURLEntry)
    entries(:nav_place, NavPlaceEntry)
  end

  @doc """
  All metadata field names, in the order the jsonb embed declared them (CSV
  export headers depend on this order)
  """
  def field_names,
    do: [
      :abstract,
      :alternate_title,
      :box_name,
      :box_number,
      :caption,
      :catalog_key,
      :citation,
      :cultural_context,
      :description,
      :folder_name,
      :folder_number,
      :identifier,
      :keywords,
      :legacy_identifier,
      :terms_of_use,
      :physical_description_material,
      :physical_description_size,
      :provenance,
      :publisher,
      :related_material,
      :rights_holder,
      :scope_and_contents,
      :series,
      :source,
      :table_of_contents,
      :title,
      :nav_place,
      :license,
      :rights_statement,
      :contributor,
      :creator,
      :genre,
      :language,
      :location,
      :style_period,
      :subject,
      :technique,
      :date_created,
      :notes,
      :related_url
    ]
end
