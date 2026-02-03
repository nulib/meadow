export const WORK_FIELDS = {
  accessionNumber: "Accession Number",
  behavior: "Behavior",
  collection: "Collection",
  descriptive_metadata: {
    abstract: "Abstract",
    alternate_title: "Alternate Title",
    box_name: "Box Name",
    box_number: "Box Number",
    caption: "Caption",
    catalog_key: "Catalog Key",
    contributor: "Contributor",
    creator: "Creator",
    cultural_context: "Cultural Context",
    date_created: "Date Created",
    description: "Description",
    folder_name: "Folder Name",
    folder_number: "Folder Number",
    genre: "Genre",
    identifier: "Identifier",
    keywords: "Keywords",
    language: "Language",
    legacy_identifier: "Legacy Identifier",
    license: "License",
    location: "Location",
    notes: "Notes",
    physical_description_material: "Physical Description Material",
    physical_description_size: "Physical Description Size",
    provenance: "Provenance",
    publisher: "Publisher",
    related_url: "Related URL",
    related_material: "Related Material",
    rights_holder: "Rights Holder",
    rights_statement: "Rights Statement",
    scope_and_contents: "Scope and Contents",
    series: "Series",
    source: "Source",
    style_period: "Style Period",
    subject: "Subject",
    table_of_contents: "Table of Contents",
    technique: "Technique",
    title: "Title",
  },
  project: "Project",
  published: "Published",
  visibility: "Visibility",
};

/**
 * Set of controlled term fields by their dotted paths
 */
export const CONTROLLED_TERM_FIELDS = new Set([
  "descriptive_metadata.contributor",
  "descriptive_metadata.creator",
  "descriptive_metadata.genre",
  "descriptive_metadata.language",
  "descriptive_metadata.location",
  "descriptive_metadata.style_period",
  "descriptive_metadata.subject",
  "descriptive_metadata.technique",
]);

/**
 * Set of coded term fields by their dotted paths
 * These are single objects with id/label/scheme that should not be recursively walked
 */
export const CODED_TERM_FIELDS = new Set([
  "descriptive_metadata.license",
  "descriptive_metadata.rights_statement",
]);

/**
 * Set of nested coded term fields by their dotted paths
 * These are arrays of objects where each object contains a coded term
 * - notes: array of {note: string, type: {id, scheme, label}}
 * - related_url: array of {url: string, label: {id, scheme, label}}
 */
export const NESTED_CODED_TERM_FIELDS = new Set([
  "descriptive_metadata.notes",
  "descriptive_metadata.related_url",
  "administrative_metadata.library_unit",
  "administrative_metadata.preservation_level",
  "administrative_metadata.status",
  "administrative_metadata.visibility",
]);

/**
 * Set of single valued text fields by their dotted paths
 */
export const TEXT_SINGLE_FIELDS = new Set([
  "descriptive_metadata.title",
  "descriptive_metadata.terms_of_use",
]);

/**
 * Set of multi valued text fields by their dotted paths
 */
export const TEXT_ARRAY_FIELDS = new Set([
  "descriptive_metadata.abstract",
  "descriptive_metadata.alternate_title",
  "descriptive_metadata.box_name",
  "descriptive_metadata.box_number",
  "descriptive_metadata.catalog_key",
  "descriptive_metadata.caption",
  "descriptive_metadata.cultural_context",
  "descriptive_metadata.description",
  "descriptive_metadata.date_created",
  "descriptive_metadata.folder_name",
  "descriptive_metadata.folder_number",
  "descriptive_metadata.identifier",
  "descriptive_metadata.keywords",
  "descriptive_metadata.legacy_identifier",
  "descriptive_metadata.physical_description_material",
  "descriptive_metadata.physical_description_size",
  "descriptive_metadata.provenance",
  "descriptive_metadata.publisher",
  "descriptive_metadata.related_material",
  "descriptive_metadata.scope_and_contents",
  "descriptive_metadata.series",
  "descriptive_metadata.source",
  "descriptive_metadata.table_of_contents",
]);