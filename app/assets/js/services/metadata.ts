type MetadataField = {
  facetComponentId?: string;
  hasRole?: boolean;
  inputEl?: string;
  name: string;
  label: string;
  metadataClass?: string;
  scheme?: string;
};

type MetadataFields = {
  [key: string]: MetadataField;
};

type AddReplaceObj = {
  add: { [key: string]: any };
  replace: { [key: string]: any };
};

export const METADATA_FIELDS: MetadataFields = {
  ABSTRACT: {
    inputEl: "textarea",
    name: "abstract",
    label: "Abstract",
    metadataClass: "descriptive",
  },
  ALTERNATE_TITLE: {
    name: "alternateTitle",
    label: "Alternate Title",
    metadataClass: "descriptive",
  },
  BOX_NAME: {
    name: "boxName",
    facetComponentId: "BoxName",
    label: "Box Name",
    metadataClass: "descriptive",
  },
  BOX_NUMBER: {
    name: "boxNumber",
    facetComponentId: "BoxNumber",
    label: "Box Number",
    metadataClass: "descriptive",
  },
  CAPTION: {
    inputEl: "textarea",
    name: "caption",
    label: "Caption",
    metadataClass: "descriptive",
  },
  CATALOG_KEY: {
    name: "catalogKey",
    label: "Catalog Key",
    metadataClass: "descriptive",
  },
  COLLECTION: {
    name: "collection",
    label: "Collection",
    metadataClass: "core",
  },
  CONTRIBUTOR: {
    hasRole: true,
    label: "Contributor",
    metadataClass: "descriptive",
    name: "contributor",
    scheme: "MARC_RELATOR",
  },
  CREATOR: { name: "creator", label: "Creator", metadataClass: "descriptive" },
  CULTURAL_CONTEXT: {
    inputEl: "textarea",
    name: "culturalContext",
    label: "Cultural Context",
    metadataClass: "descriptive",
  },
  DATE_CREATED: {
    name: "dateCreated",
    label: "Date Created",
    metadataClass: "descriptive",
  },
  DESCRIPTION: {
    name: "description",
    label: "Description",
    metadataClass: "descriptive",
  },
  FOLDER_NAME: {
    name: "folderName",
    facetComponentId: "FolderName",
    label: "Folder Name",
    metadataClass: "descriptive",
  },
  FOLDER_NUMBER: {
    name: "folderNumber",
    facetComponentId: "FolderName",
    label: "Folder Number",
    metadataClass: "descriptive",
  },
  GENRE: { name: "genre", label: "Genre", metadataClass: "descriptive" },
  IDENTIFIER: {
    name: "identifier",
    label: "Identifier",
    metadataClass: "descriptive",
  },
  KEYWORDS: {
    name: "keywords",
    label: "Keywords",
    metadataClass: "descriptive",
  },
  LANGUAGE: {
    name: "language",
    label: "Language",
    metadataClass: "descriptive",
  },
  LEGACY_IDENTIFIER: {
    name: "legacyIdentifier",
    label: "Legacy Identifier",
    metadataClass: "descriptive",
  },
  LIBRARY_UNIT: {
    name: "libraryUnit",
    label: "Library Unit",
    metadataClass: "administrative",
  },
  LICENSE: { name: "license", label: "License", metadataClass: "" },
  LOCATION: {
    name: "location",
    label: "Location",
    metadataClass: "descriptive",
  },
  NOTES: {
    inputEl: "textarea",
    name: "notes",
    label: "Notes",
    metadataClass: "descriptive",
  },
  PHYSICAL_DESCRIPTION_MATERIAL: {
    name: "physicalDescriptionMaterial",
    label: "Physical Description Material",
    metadataClass: "descriptive",
  },
  PHYSICAL_DESCRIPTION_SIZE: {
    name: "physicalDescriptionSize",
    label: "Physical Description Size",
    metadataClass: "descriptive",
  },
  PRESERVATION_LEVEL: {
    name: "preservationLevel",
    label: "Preservation Level",
    metadataClass: "administrative",
  },
  PROJECT_CYCLE: {
    name: "projectCycle",
    label: "Project Cycle",
    metadataClass: "administrative",
  },
  PROJECT_DESC: {
    name: "projectDesc",
    label: "Project / Job Description",
    metadataClass: "administrative",
  },
  PROJECT_MANAGER: {
    name: "projectManager",
    label: "Project / Job Manager",
    metadataClass: "administrative",
  },
  PROJECT_NAME: {
    name: "projectName",
    label: "Project / Job Name",
    metadataClass: "administrative",
  },
  PROJECT_PROPOSER: {
    name: "projectProposer",
    label: "Project / Job Proposer",
    metadataClass: "administrative",
  },
  PROJECT_TASK_NUMBER: {
    name: "projectTaskNumber",
    label: "Project / Job Task Number",
    metadataClass: "administrative",
  },
  PROVENANCE: {
    inputEl: "textarea",
    name: "provenance",
    label: "Provenance",
    metadataClass: "descriptive",
  },
  PUBLISHED: { name: "published", label: "Published", metadataClass: "core" },
  PUBLISHER: {
    name: "publisher",
    label: "Publisher",
    metadataClass: "descriptive",
  },
  RELATED_MATERIAL: {
    name: "relatedMaterial",
    label: "Related Material",
    metadataClass: "descriptive",
  },
  RELATED_URL: {
    name: "relatedUrl",
    label: "Related URL",
    metadataClass: "descriptive",
  },
  RIGHTS_HOLDER: {
    name: "rightsHolder",
    label: "Rights Holder",
    metadataClass: "descriptive",
  },
  RIGHTS_STATEMENT: {
    name: "rightsStatement",
    label: "Rights Statement",
    metadataClass: "descriptive",
  },
  SCOPE_AND_CONTENT: {
    name: "scopeAndContents",
    label: "Scope and Content",
    metadataClass: "descriptive",
  },
  SERIES: {
    name: "series",
    facetComponentId: "Series",
    label: "Series",
    metadataClass: "descriptive",
  },
  SOURCE: { name: "source", label: "Source", metadataClass: "descriptive" },
  STATUS: { name: "status", label: "Status", metadataClass: "core" },
  STYLE_PERIOD: {
    name: "stylePeriod",
    label: "Style Period",
    metadataClass: "descriptive",
  },
  SUBJECT_ROLE: {
    hasRole: true,
    label: "Subject",
    metadataClass: "descriptive",
    name: "subject",
    scheme: "SUBJECT_ROLE",
  },
  TABLE_OF_CONTENTS: {
    inputEl: "textarea",
    name: "tableOfContents",
    label: "Table of Contents",
    metadataClass: "descriptive",
  },
  TECHNIQUE: {
    label: "Technique",
    name: "technique",
    metadataClass: "descriptive",
  },
  TITLE: { name: "title", label: "Title", metadataClass: "descriptive" },
  VISIBILITY: {
    name: "visibility",
    label: "Visibility",
    metadataClass: "core",
  },
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
  CULTURAL_CONTEXT,
  DATE_CREATED,
  DESCRIPTION,
  FOLDER_NAME,
  FOLDER_NUMBER,
  GENRE,
  IDENTIFIER,
  KEYWORDS,
  LANGUAGE,
  LEGACY_IDENTIFIER,
  LIBRARY_UNIT,
  LICENSE,
  LOCATION,
  NOTES,
  PHYSICAL_DESCRIPTION_MATERIAL,
  PHYSICAL_DESCRIPTION_SIZE,
  PRESERVATION_LEVEL,
  PROJECT_CYCLE,
  PROJECT_DESC,
  PROJECT_MANAGER,
  PROJECT_NAME,
  PROJECT_PROPOSER,
  PROJECT_TASK_NUMBER,
  PROVENANCE,
  PUBLISHED,
  PUBLISHER,
  RELATED_MATERIAL,
  RELATED_URL,
  RIGHTS_HOLDER,
  RIGHTS_STATEMENT,
  SCOPE_AND_CONTENT,
  SERIES,
  SOURCE,
  STATUS,
  STYLE_PERIOD,
  SUBJECT_ROLE,
  TABLE_OF_CONTENTS,
  TECHNIQUE,
  TITLE,
  VISIBILITY,
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
  CULTURAL_CONTEXT,
  DATE_CREATED,
  DESCRIPTION,
  FOLDER_NAME,
  FOLDER_NUMBER,
  IDENTIFIER,
  KEYWORDS,
  LEGACY_IDENTIFIER,
  PHYSICAL_DESCRIPTION_MATERIAL,
  PHYSICAL_DESCRIPTION_SIZE,
  PRESERVATION_LEVEL,
  PROVENANCE,
  PUBLISHER,
  RELATED_MATERIAL,
  RIGHTS_HOLDER,
  SCOPE_AND_CONTENT,
  SERIES,
  SOURCE,
  STATUS,
  TABLE_OF_CONTENTS,
  VISIBILITY,
];

export const PROJECT_METADATA = [
  PROJECT_NAME,
  PROJECT_DESC,
  PROJECT_MANAGER,
  PROJECT_PROPOSER,
  PROJECT_TASK_NUMBER,
];

export const OTHER_METADATA = [
  ALTERNATE_TITLE,
  DATE_CREATED,
  DESCRIPTION,
  LICENSE,
  NOTES,
  RELATED_URL,
  RIGHTS_STATEMENT,
  TITLE,
];

export const UNCONTROLLED_METADATA = [
  ABSTRACT,
  CAPTION,
  CULTURAL_CONTEXT,
  KEYWORDS,
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
    NOTES,
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
export function getBatchMultiValueDataFromForm(currentFormValues: {
  [key: string]: any;
}) {
  let returnObj: AddReplaceObj = { add: {}, replace: {} };
  const formDataKeys = Object.keys(currentFormValues);
  const metadataNames = UNCONTROLLED_MULTI_VALUE_METADATA.map(
    (umvm) => umvm.name,
  );

  // Filter form values by multi value entries only
  const formMultiOnly = formDataKeys.filter(
    (formItem) => metadataNames.indexOf(formItem.split("--")[0]) > -1,
  );

  for (const key of formMultiOnly) {
    let rootName = key.split("--")[0];
    let editType = key.split("--")[1] ? currentFormValues[key] : "";
    // Replace all = delete. Handle "replace all" condition
    if (editType === "delete") {
      returnObj.replace[rootName] = [];
    }
    if (editType === "append" && formMultiOnly.indexOf(rootName) > -1) {
      returnObj.add[rootName] = [...currentFormValues[rootName]];
    }
    if (editType === "replace" && formMultiOnly.indexOf(rootName) > -1) {
      returnObj.replace[rootName] = [...currentFormValues[rootName]];
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

export function getMetadataLabel(name: string) {
  let foundItem = Object.keys(METADATA_FIELDS).filter(
    (key) => METADATA_FIELDS[key].name === name,
  );
  return METADATA_FIELDS[foundItem[0]].label;
}

export function findScheme(termToFind: MetadataField | undefined) {
  if (!termToFind) return "";
  let term = CONTROLLED_METADATA.find((ct) => ct.name === termToFind.name);
  return term?.scheme || "";
}

export function hasRole(name: string) {
  const controlledTermItem = DESCRIPTIVE_METADATA.controlledTerms.find(
    (obj) => obj.name === name,
  );
  return controlledTermItem?.hasRole;
}

/**
 * Filter a mixture of "administrative" and "descriptive" Batch Edit form metadata multivalues
 * @param {Object} multiValues Mixture of values
 * @param {String} metadataClass "administrative" or "descriptive"
 * @returns {Object} Filtered values according to metadataClass
 */
export function parseMultiValues(
  multiValues = {},
  metadataClass = "descriptive",
) {
  let { add = {}, replace = {} } = multiValues as AddReplaceObj;
  let returnObj: AddReplaceObj = {
    add: {},
    replace: {},
  };
  const metadataItems = Object.keys(METADATA_FIELDS)
    .map((key) => METADATA_FIELDS[key])
    .filter((obj) => obj.metadataClass === metadataClass);

  function grabTheValues(obj: { [key: string]: any }) {
    let o: {
      [key: string]: any;
    } = {};
    if (Object.keys(obj).length > 0) {
      for (const name in obj) {
        const metaDataField = metadataItems.find((i) => i.name === name);
        if (metaDataField) {
          o[name] = [...obj[name]];
        }
      }
    }
    return o;
  }

  returnObj.add = grabTheValues(add);
  returnObj.replace = grabTheValues(replace);

  return returnObj;
}

/**
 * Shapes React Hook Form array fields of type "Controlled Term"
 * into the POST format the API wants
 * @param {Object} controlledTerm Individual object from DESCRIPTIVE_METADATA.controlledTerm constant
 * @param {Array} formItems All entries (one to many) of a controlled term metadata field
 * @returns {Array} // Currently the shape the API wants is [{ term: "ABC", role: { id: "XYZ", scheme: "THE_SCHEME" } }]
 */
export function prepControlledTermInput(
  controlledTerm?: MetadataField,
  formItems: Array<{
    authority?: string;
    label: string;
    roleId?: string;
    termId: string;
  }> = [],
  includeLabel = false,
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
      let obj: {
        label?: string;
        role?: { id: string; scheme: string };
        term: string;
      } = { term: termId };
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
export function prepFieldArrayItemsForPost(
  items: Array<{ metadataItem: string }> = [],
) {
  return items.map(({ metadataItem }) => metadataItem);
}

/**
 * Convert coded term select options to include scheme
 * @param {Array} codeListsData Array of object entries
 * @param {String} codedTerm String representing codedTermScheme
 * @returns {Array} Array of modified object entries
 */
export function getCodedTermSelectOptions(
  codeListsData: Array<{ id: string; label: string }> = [],
  codedTerm = "",
) {
  return codeListsData.map((option) => {
    return {
      ...option,
      id: JSON.stringify({
        id: option.id,
        scheme: codedTerm,
        label: option.label,
      }),
    };
  });
}

/**
 * Prepares fieldArray form data for an upcoming GraphQL post
 * @param {Object} controlledTerm
 * @param {Array} keyItems
 * @returns {Array}
 */
export function prepFacetKey(
  controlledTerm: MetadataField,
  keyItems: Array<string> = [],
) {
  let arr = keyItems.map((item) => {
    const itemArr = item.split("|");
    const term = itemArr[0];
    const roleId = itemArr[1];
    const label = itemArr[2];

    let obj: {
      label?: string;
      role?: { id: string; scheme: string };
      term?: string;
    } = { term, label };
    if (roleId) {
      obj.role = { id: roleId, scheme: findScheme(controlledTerm) };
    }
    return obj;
  });

  return arr;
}

/**
 * Prepares Notes form data for an upcoming GraphQL post
 */
export function prepNotes(
  items: Array<{
    note: string;
    typeId: string;
  }> = [],
) {
  try {
    return items.map((item) => ({
      note: item.note,
      type: {
        scheme: "NOTE_TYPE",
        id: item.typeId,
      },
    }));
  } catch (e) {
    console.error("Error preparing Notes value for form post");
    return [];
  }
}

/**
 * Prepares Related Url form data for an upcoming GraphQL post
 */
export function prepRelatedUrl(
  items: Array<{
    url: string;
    labelId: string;
  }> = [],
) {
  try {
    return items.map((item) => ({
      url: item.url,
      label: {
        scheme: "RELATED_URL",
        id: item.labelId,
      },
    }));
  } catch (e) {
    console.error("Error preparing Related Url value for form post");
    return [];
  }
}

/**
 * Helper function which removes label from a given object
 */
export function deleteKeyFromObject(item: any) {
  if (
    typeof item !== "object" ||
    Array.isArray(item) ||
    item.hasOwnProperty("url")
  ) {
    return item;
  }
  let itemObj = { ...item };
  delete itemObj.label;
  return itemObj;
}

export function prepEDTFforPost(
  items: Array<{
    metadataItem: string;
  }> = [],
) {
  return items.map((item) => {
    return { edtf: item.metadataItem || item };
  });
}

/**
 * Remove helper labels from Batch Edit form post data
 */
export function removeLabelsFromBatchEditPostData(
  batchAdds: {
    [key: string]: any;
    descriptiveMetadata: { [key: string]: any };
    administrativeMetadata: { [key: string]: any };
  },
  batchDeletes: {
    [key: string]: any;
  },
  batchReplaces: {
    [key: string]: any;
  },
  hasAdds?: boolean,
  hasDeletes?: boolean,
  hasReplaces?: boolean,
) {
  type ReturnObj = {
    add: {
      descriptiveMetadata: { [key: string]: any };
      administrativeMetadata: { [key: string]: any };
    };
    delete: { [key: string]: any };
    replace: {
      descriptiveMetadata: { [key: string]: any };
      administrativeMetadata: { [key: string]: any };
      published?: boolean;
    };
  };

  let returnObj: ReturnObj = {
    add: { descriptiveMetadata: {}, administrativeMetadata: {} },
    delete: {},
    replace: { administrativeMetadata: {}, descriptiveMetadata: {} },
  };

  if (hasAdds) {
    batchAdds.descriptiveMetadata &&
      Object.keys(batchAdds.descriptiveMetadata).forEach((key) => {
        returnObj.add.descriptiveMetadata[key] = batchAdds.descriptiveMetadata[
          key
        ].map((item: any) => {
          if (key === "dateCreated") {
            return { edtf: item };
          }
          return deleteKeyFromObject(item);
        });
      });
    batchAdds.administrativeMetadata &&
      Object.keys(batchAdds.administrativeMetadata).forEach((key) => {
        returnObj.add.administrativeMetadata[key] =
          batchAdds.administrativeMetadata[key].map((item: any) => {
            return deleteKeyFromObject(item);
          });
      });
  }

  if (hasReplaces) {
    batchReplaces.descriptiveMetadata &&
      Object.keys(batchReplaces.descriptiveMetadata).forEach((key) => {
        let item = batchReplaces.descriptiveMetadata[key];
        if (key === "dateCreated") {
          returnObj.replace.descriptiveMetadata[key] = prepEDTFforPost(item);
        } else {
          returnObj.replace.descriptiveMetadata[key] =
            deleteKeyFromObject(item);
        }
      });
    batchReplaces.administrativeMetadata &&
      Object.keys(batchReplaces.administrativeMetadata).forEach((key) => {
        let item = batchReplaces.administrativeMetadata[key];
        returnObj.replace.administrativeMetadata[key] =
          deleteKeyFromObject(item);
      });

    // Handle published or unpublished values
    // The "published" object can only have one of its properties set
    // to TRUE... "publish" or "unpublish".  Not both.
    const { published } = batchReplaces;
    if (published && (published.publish || published.unpublish)) {
      returnObj.replace.published = published.publish;
    }
  }

  if (hasDeletes) {
    Object.keys(batchDeletes).forEach((key) => {
      returnObj.delete[key] = batchDeletes[key].map((item: any) => {
        return deleteKeyFromObject(item);
      });
    });
  }

  return returnObj;
}

/**
 * Helper function which parses the facet key used in Batch Edits
 */
export function splitFacetKey(key: string) {
  const arr = key.split("|");

  return {
    term: arr[0],
    role: arr[1],
    label: arr[2],
  };
}

export function convertFieldArrayValToHookFormVal(value: any) {
  return { metadataItem: value };
}
