export const CONTROLLED_METADATA = [
  {
    hasRole,
    label: "Contributor",
    name: "contributor",
    scheme: "MARC_RELATOR",
  },
  {
    label: "Creators",
    name: "creator",
  },
  {
    label: "Genre",
    name: "genre",
  },
  {
    label: "Language",
    name: "language",
  },
  {
    label: "Location",
    name: "location",
  },
  {
    label: "Style Period",
    name: "stylePeriod",
  },
  {
    hasRole,
    label: "Subject",
    name: "subject",
    scheme: "SUBJECT_ROLE",
  },
  {
    label: "Technique",
    name: "technique",
  },
];

export const UNCONTROLLED_METADATA = [
  { name: "abstract", label: "Abstract" },
  { name: "caption", label: "Caption" },
  { name: "keywords", label: "Keywords" },
  { name: "notes", label: "Notes" },
  { name: "tableOfContents", label: "Table of Contents" },
];

export const PHYSICAL_METADATA = [
  {
    name: "physicalDescriptionMaterial",
    label: "Physical Description Material",
  },
  {
    name: "physicalDescriptionSize",
    label: "Physical Description Size",
  },
  { name: "boxName", label: "Box Name" },
  { name: "boxNumber", label: "Box Number" },
  { name: "folderName", label: "Folder Name" },
  { name: "folderNumber", label: "Folder Number" },
  { name: "scopeAndContents", label: "Scope and Content" },
  { name: "series", label: "Series" },
];

export const RIGHTS_METADATA = [
  { name: "publisher", label: "Publisher" },
  { name: "provenance", label: "Provenance" },
  { name: "rightsHolder", label: "Rights Holder" },
];

export const IDENTIFIER_METADATA = [
  { name: "identifier", label: "Identifier" },
  { name: "legacyIdentifier", label: "Legacy Identifier" },
  { name: "callNumber", label: "Call Number" },
  { name: "catalogKey", label: "Catalog Key" },
  { name: "relatedMaterial", label: "Related Material" },
  { name: "source", label: "Source" },
];

export const DESCRIPTIVE_METADATA = {
  controlledTerms: [
    {
      hasRole,
      label: "Contributor",
      name: "contributor",
      scheme: "MARC_RELATOR",
    },
    {
      label: "Creators",
      name: "creator",
    },
    {
      label: "Genre",
      name: "genre",
    },
    {
      label: "Language",
      name: "language",
    },
    {
      label: "Location",
      name: "location",
    },
    {
      label: "Style Period",
      name: "stylePeriod",
    },
    {
      hasRole,
      label: "Subject",
      name: "subject",
      scheme: "SUBJECT_ROLE",
    },
    {
      label: "Technique",
      name: "technique",
    },
  ],
};

export function findScheme(termToFind) {
  let term = CONTROLLED_METADATA.find((ct) => ct.name === termToFind.name);
  return term.scheme || "";
}

/**
 * Shapes React Hook Form array fields of type "Controlled Term"
 * into the POST format the API wants
 * @param {Object} controlledTerm Individual object from DESCRIPTIVE_METADATA.controlledTerm constant
 * @param {Array} formItems All entries (one to many) of a controlled term metadata field
 * @returns {Array} // Currently the shape the API wants is [{ term: "ABC", role: { id: "XYZ", scheme: "THE_SCHEME" } }]
 */
export function prepControlledTermInput(controlledTerm = {}, formItems = []) {
  let arr = formItems.map(({ termId, roleId }) => {
    let obj = { term: termId };
    if (roleId) {
      obj.role = { id: roleId, scheme: findScheme(controlledTerm) };
    }
    return obj;
  });

  return arr;
}

export function hasRole(name) {
  const controlledTermItem = DESCRIPTIVE_METADATA.controlledTerms.find(
    (obj) => obj.name === name
  );
  return controlledTermItem.hasRole;
}
