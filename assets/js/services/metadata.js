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
export const PROJECT_METADATA = [
  { name: "projectDesc", label: "Project Description" },
  { name: "projectManager", label: "Project Manager" },
  { name: "projectName", label: "Project Name" },
  { name: "projectProposer", label: "Project Proposer" },
  { name: "projectTaskNumber", label: "Project Task Number" },
];

export const OTHER_METADATA = [
  { name: "alternateTitle", label: "Alternate Title" },
  { name: "dateCreated", label: "Date Created" },
  { name: "description", label: "Description" },
  { name: "license", label: "License" },
  { name: "relatedUrl", label: "Related URL" },
  { name: "rightsStatement", label: "Rights Statement" },
  { name: "title", label: "Title" },
];

export const UNCONTROLLED_METADATA = [
  { name: "abstract", label: "Abstract" },
  { name: "caption", label: "Caption" },
  { name: "keywords", label: "Keywords" },
  { name: "notes", label: "Notes" },
  { name: "tableOfContents", label: "Table of Contents" },
];

export const PHYSICAL_METADATA = [
  { name: "boxName", label: "Box Name" },
  { name: "boxNumber", label: "Box Number" },
  { name: "folderName", label: "Folder Name" },
  { name: "folderNumber", label: "Folder Number" },
  {
    name: "physicalDescriptionMaterial",
    label: "Physical Description Material",
  },
  {
    name: "physicalDescriptionSize",
    label: "Physical Description Size",
  },
  { name: "scopeAndContents", label: "Scope and Content" },
  { name: "series", label: "Series" },
];

export const RIGHTS_METADATA = [
  { name: "provenance", label: "Provenance" },
  { name: "publisher", label: "Publisher" },
  { name: "rightsHolder", label: "Rights Holder" },
];

export const IDENTIFIER_METADATA = [
  { name: "catalogKey", label: "Catalog Key" },
  { name: "identifier", label: "Identifier" },
  { name: "legacyIdentifier", label: "Legacy Identifier" },
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

export function hasRole(name) {
  const controlledTermItem = DESCRIPTIVE_METADATA.controlledTerms.find(
    (obj) => obj.name === name
  );
  return controlledTermItem.hasRole;
}

/**
 * Shapes React Hook Form array fields of type "Controlled Term"
 * into the POST format the API wants
 * @param {Object} controlledTerm Individual object from DESCRIPTIVE_METADATA.controlledTerm constant
 * @param {Array} formItems All entries (one to many) of a controlled term metadata field
 * @returns {Array} // Currently the shape the API wants is [{ term: "ABC", role: { id: "XYZ", scheme: "THE_SCHEME" } }]
 */
export function prepControlledTermInput(
  controlledTerm = {},
  formItems = [],
  includeLabel = false
) {
  // First, filter out any controlled term fieldsets which come through without
  // a valid controlled term id selected
  let arr = formItems
    .filter((item) => {
      if (!item.termId) {
        return false;
      }
      return true;
    })
    // Next prepare the object in the right shape
    .map(({ termId, roleId, label }) => {
      let obj = { term: termId };
      if (roleId) {
        obj.role = { id: roleId, scheme: findScheme(controlledTerm) };
      }
      if (includeLabel) {
        obj.label = label;
      }
      return obj;
    });

  return arr;
}

/**
 * Convert form field array items from an array of objects to array of strings
 * @param {Array} items Array of object entries possible in form
 * @returns {Array} Array of strings
 */
export function prepFieldArrayItemsForPost(items = []) {
  return items.map(({ metadataItem }) => metadataItem);
}

/**
 * Prepares fieldArray form data for an upcoming GraphQL post
 * @param {Object} controlledTerm
 * @param {Array} keyItems
 * @returns {Array}
 */
export function prepFacetKey(controlledTerm = {}, keyItems = []) {
  let arr = keyItems.map((item) => {
    const itemArr = item.split("|");
    const term = itemArr[0];
    const roleId = itemArr[1];
    const label = itemArr[2];

    let obj = { term, label };
    if (roleId) {
      obj.role = { id: roleId, scheme: findScheme(controlledTerm) };
    }
    return obj;
  });

  return arr;
}

/**
 * Prepares Related Url form data for an upcoming GraphQL post
 * @param {Array} items Array of object entries possible in form
 * @returns {Array} of properly shaped values for Related Url
 */
export function prepRelatedUrl(items = []) {
  let returnArray = [];

  returnArray = items.map((item) => {
    return {
      url: item.url,
      label: {
        scheme: "RELATED_URL",
        id: item.label,
      },
    };
  });

  // Check for empty values caused by any kind of error
  const badData = returnArray.find((item) => !item.url || !item.label.id);
  if (badData) {
    console.log("Error preparing Related Url value for form post");
  }

  return badData ? [] : returnArray;
}

/**
 * Remove helper labels from Batch Edit form post data
 * @param {Object} batchAdds
 * @param {Object} batchDeletes
 * @param {Boolean} hasAdds
 * @param {Boolean} hasDeletes
 *
 * @returns {Object}
 */
export function removeLabelsFromBatchEditPostData(
  batchAdds,
  batchDeletes,
  hasAdds,
  hasDeletes
) {
  let returnObj = { add: { descriptiveMetadata: {} }, delete: {} };

  if (hasAdds) {
    Object.keys(batchAdds.descriptiveMetadata).forEach((key) => {
      returnObj.add.descriptiveMetadata[key] = batchAdds.descriptiveMetadata[
        key
      ].map((item) => {
        let itemObj = { ...item };
        delete itemObj.label;
        return itemObj;
      });
    });
  }

  if (hasDeletes) {
    Object.keys(batchDeletes).forEach((key) => {
      returnObj.delete[key] = batchDeletes[key].map((item) => {
        let itemObj = { ...item };
        delete itemObj.label;
        return itemObj;
      });
    });
  }

  return returnObj;
}

/**
 * Helper function which parses the facet key used in Batch Edits
 * @param {String} key
 * @returns {Object}
 */
export function splitFacetKey(key) {
  const arr = key.split("|");

  return {
    term: arr[0],
    role: arr[1],
    label: arr[2],
  };
}

export function convertFieldArrayValToHookFormVal(value) {
  return { metadataItem: value };
}
