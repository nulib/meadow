export const METADATA_FIELDS = {
  ABSTRACT: { name: "abstract", label: "Abstract" },
  ALTERNATE_TITLE: {
    name: "alternateTitle",
    label: "Alternate Title",
  },
  BOX_NAME: { name: "boxName", label: "Box Name" },
  BOX_NUMBER: { name: "boxNumber", label: "Box Number" },
  CAPTION: { name: "caption", label: "Caption" },
  CATALOG_KEY: { name: "catalogKey", label: "Catalog Key" },
  CONTRIBUTOR: {
    hasRole: true,
    label: "Contributor",
    name: "contributor",
    scheme: "MARC_RELATOR",
  },
  CREATOR: { name: "creator", label: "Creator" },
  DATE_CREATED: { name: "dateCreated", label: "Date Created" },
  DESCRIPTION: { name: "description", label: "Description" },
  FOLDER_NAME: { name: "folderName", label: "Folder Name" },
  FOLDER_NUMBER: { name: "folderNumber", label: "Folder Number" },
  GENRE: { name: "genre", label: "Genre" },
  IDENTIFIER: { name: "identifier", label: "Identifier" },
  KEYWORDS: { name: "keywords", label: "Keywords" },
  LANGUAGE: { name: "language", label: "Language" },
  LEGACY_IDENTIFIER: { name: "legacyIdentifier", label: "Legacy Identifier" },
  LICENSE: { name: "license", label: "License" },
  LOCATION: { name: "location", label: "Location" },
  NOTES: { name: "notes", label: "Notes" },
  PHYSICAL_DESCRIPTION_MATERIAL: {
    name: "physicalDescriptionMaterial",
    label: "Physical Description Material",
  },
  PHYSICAL_DESCRIPTION_SIZE: {
    name: "physicalDescriptionSize",
    label: "Physical Description Size",
  },
  PROVENANCE: { name: "provenance", label: "Provenance" },
  PUBLISHER: { name: "publisher", label: "Publisher" },
  RELATED_MATERIAL: { name: "relatedMaterial", label: "Related Material" },
  RELATED_URL: { name: "relatedUrl", label: "Related URL" },
  RIGHTS_HOLDER: { name: "rightsHolder", label: "Rights Holder" },
  RIGHTS_STATEMENT: { name: "rightsStatement", label: "Rights Statement" },
  SCOPE_AND_CONTENT: { name: "scopeAndContents", label: "Scope and Content" },
  SERIES: { name: "series", label: "Series" },
  SOURCE: { name: "source", label: "Source" },
  STYLE_PERIOD: { name: "stylePeriod", label: "Style Period" },
  SUBJECT_ROLE: {
    hasRole,
    label: "Subject",
    name: "subject",
    scheme: "SUBJECT_ROLE",
  },
  TABLE_OF_CONTENTS: { name: "tableOfContents", label: "Table of Contents" },
  TECHNIQUE: { label: "Technique", name: "technique" },
  TITLE: { name: "title", label: "Title" },
};

const {
  ABSTRACT,
  ALTERNATE_TITLE,
  BOX_NAME,
  BOX_NUMBER,
  CAPTION,
  CATALOG_KEY,
  CONTRIBUTOR,
  CREATOR,
  DATE_CREATED,
  DESCRIPTION,
  FOLDER_NAME,
  FOLDER_NUMBER,
  GENRE,
  IDENTIFIER,
  KEYWORDS,
  LANGUAGE,
  LEGACY_IDENTIFIER,
  LICENSE,
  LOCATION,
  NOTES,
  PHYSICAL_DESCRIPTION_MATERIAL,
  PHYSICAL_DESCRIPTION_SIZE,
  PROVENANCE,
  PUBLISHER,
  RELATED_MATERIAL,
  RELATED_URL,
  RIGHTS_HOLDER,
  RIGHTS_STATEMENT,
  SCOPE_AND_CONTENT,
  SERIES,
  SOURCE,
  STYLE_PERIOD,
  SUBJECT_ROLE,
  TABLE_OF_CONTENTS,
  TECHNIQUE,
  TITLE,
} = METADATA_FIELDS;

export const CONTROLLED_METADATA = [
  CONTRIBUTOR,
  CREATOR,
  GENRE,
  LANGUAGE,
  LOCATION,
  STYLE_PERIOD,
  SUBJECT_ROLE,
  TECHNIQUE,
];

export const UNCONTROLLED_MULTI_VALUE_METADATA = [
  ABSTRACT,
  ALTERNATE_TITLE,
  BOX_NAME,
  BOX_NUMBER,
  CAPTION,
  CATALOG_KEY,
  FOLDER_NAME,
  FOLDER_NUMBER,
  IDENTIFIER,
  KEYWORDS,
  LEGACY_IDENTIFIER,
  NOTES,
  PHYSICAL_DESCRIPTION_MATERIAL,
  PHYSICAL_DESCRIPTION_SIZE,
  PROVENANCE,
  PUBLISHER,
  RELATED_MATERIAL,
  RIGHTS_HOLDER,
  SCOPE_AND_CONTENT,
  SERIES,
  SOURCE,
  TABLE_OF_CONTENTS,
];

export const PROJECT_METADATA = [
  { name: "projectDesc", label: "Project Description" },
  { name: "projectManager", label: "Project Manager" },
  { name: "projectName", label: "Project Name" },
  { name: "projectProposer", label: "Project Proposer" },
  { name: "projectTaskNumber", label: "Project Task Number" },
];

export const OTHER_METADATA = [
  ALTERNATE_TITLE,
  DATE_CREATED,
  DESCRIPTION,
  LICENSE,
  RELATED_URL,
  RIGHTS_STATEMENT,
  TITLE,
];

export const UNCONTROLLED_METADATA = [
  ABSTRACT,
  CAPTION,
  KEYWORDS,
  NOTES,
  TABLE_OF_CONTENTS,
];

export const PHYSICAL_METADATA = [
  BOX_NAME,
  BOX_NUMBER,
  FOLDER_NAME,
  FOLDER_NUMBER,
  PHYSICAL_DESCRIPTION_MATERIAL,
  PHYSICAL_DESCRIPTION_SIZE,
  SCOPE_AND_CONTENT,
  SERIES,
];

export const RIGHTS_METADATA = [PROVENANCE, PUBLISHER, RIGHTS_HOLDER];

export const IDENTIFIER_METADATA = [
  CATALOG_KEY,
  IDENTIFIER,
  LEGACY_IDENTIFIER,
  RELATED_MATERIAL,
  SOURCE,
];

export const DESCRIPTIVE_METADATA = {
  controlledTerms: [
    CONTRIBUTOR,
    CREATOR,
    GENRE,
    LANGUAGE,
    LOCATION,
    STYLE_PERIOD,
    SUBJECT_ROLE,
    TECHNIQUE,
  ],
};

/**
 * Prepare an object of adds and replaces for uncontrolled, multi-value fields
 * from batch edit form values
 * @param {Object} currentFormValues React Hook Form getValues() return obj
 * @returns {Object} // 2 children objects "add" and "replace"
 */
export function getBatchMultiValueDataFromForm(currentFormValues) {
  let returnObj = { add: {}, replace: {} };
  const formDataKeys = Object.keys(currentFormValues);
  const metadataNames = UNCONTROLLED_MULTI_VALUE_METADATA.map(
    (umvm) => umvm.name
  );

  // Filter form values by multi value entries only
  const formMultiOnly = formDataKeys.filter(
    (formItem) => metadataNames.indexOf(formItem.split("--")[0]) > -1
  );

  for (const key of formMultiOnly) {
    // Handle "replace all" condition
    if (key.includes("removeCheckbox") && currentFormValues[key]) {
      returnObj.replace[key.split("--")[0]] = [];
    }
    // Handle "replace" or "add"
    else {
      let rootName = key.split("--")[0];
      // Verify a value exists
      if (
        key.includes("replaceCheckbox") &&
        formMultiOnly.indexOf(rootName) > -1
      ) {
        returnObj[currentFormValues[key] ? "replace" : "add"][rootName] = [
          ...currentFormValues[rootName],
        ];
      }
    }
  }

  // Clean up the data for form post
  let adds = Object.keys(returnObj.add);
  let replaces = Object.keys(returnObj.replace);

  if (adds.length > 0) {
    for (let elName of adds) {
      returnObj.add[elName] = [
        ...prepFieldArrayItemsForPost(returnObj.add[elName]),
      ];
    }
  }
  if (replaces.length > 0) {
    for (let elName of replaces) {
      returnObj.replace[elName] = [
        ...prepFieldArrayItemsForPost(returnObj.replace[elName]),
      ];
    }
  }

  return returnObj;
}

export function getMetadataLabel(name) {
  let foundItem = Object.keys(METADATA_FIELDS).filter(
    (key) => METADATA_FIELDS[key].name === name
  );
  return METADATA_FIELDS[foundItem[0]].label;
}

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
        // Regular string value
        if (typeof item !== "object") {
          return item;
        }
        // Controlled term object value
        let itemObj = { ...item };
        delete itemObj.label;
        return itemObj;
      });
    });
  }

  if (hasDeletes) {
    Object.keys(batchDeletes).forEach((key) => {
      returnObj.delete[key] = batchDeletes[key].map((item) => {
        // Regular string value
        if (typeof item !== "object") {
          return item;
        }
        // Controlled term object value
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
