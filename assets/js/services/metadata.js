export const DESCRIPTIVE_METADATA = {
  controlledTerms: [
    {
      hasRole,
      label: "Contributor",
      name: "contributor",
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
    },
    {
      label: "Technique",
      name: "technique",
    },
  ],

  // Form metadata items which can have multiple "string" type values, handled in "FieldArray" components
  fieldArrays: [
    { name: "abstract", label: "Abstract" },
    { name: "alternateTitle", label: "Alternate Title" },
    { name: "boxName", label: "Box Name" },
    { name: "boxNumber", label: "Box Number" },
    { name: "callNumber", label: "Call Number" },
    { name: "caption", label: "Caption" },
    { name: "catalogKey", label: "Catalog Key" },
    { name: "folderName", label: "Folder Name" },
    { name: "folderNumber", label: "Folder Number" },
    { name: "identifier", label: "Identifier" },
    { name: "keywords", label: "Keywords" },
    { name: "legacyIdentifier", label: "Legacy Identifier" },
    { name: "notes", label: "Notes" },
    {
      name: "physicalDescriptionMaterial",
      label: "Physical Description Material",
    },
    {
      name: "physicalDescriptionSize",
      label: "Physical Description Size",
    },
    { name: "provenance", label: "Provenance" },
    { name: "publisher", label: "Publisher" },
    { name: "relatedUrl", label: "Related URL" },
    { name: "relatedMaterial", label: "Related Material" },
    { name: "rightsHolder", label: "Rights Holder" },
    { name: "scopeAndContents", label: "Scope and Content" },
    { name: "series", label: "Series" },
    { name: "source", label: "Source" },
    { name: "tableOfContents", label: "Table of Contents" },
  ],
};

/**
 * Prepares React Hook Form array fields of type "Controlled Term"
 * for the form request post shape
 * @param {Array} arr
 * @returns {Array} // Currently the shape the API wants is [{ id: "ABC", role: { id: "XYZ" } }]
 */
export function prepControlledTermInput(formItems = []) {
  return formItems.map(({ id, roleId }) => {
    let obj = { id };
    if (roleId) {
      obj.role = { id: roleId };
    }
    return obj;
  });
}

export function hasRole(name) {
  const controlledTermItem = DESCRIPTIVE_METADATA.controlledTerms.find(
    (obj) => obj.name === name
  );
  return controlledTermItem.hasRole;
}
