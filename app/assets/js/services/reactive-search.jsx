import React from "react";

export const FACET_RANGE_SENSOR = "FacetRangeSensor";
export const RESULT_SENSOR = "SearchResult";
export const SEARCH_SENSOR = "q";
export const REACTIVE_SEARCH_THEME = {
  typography: {
    fontFamily: "Akkurat Pro Regular",
  },
};

/**
 * Helper function to parse out text presented to the user in Facet labels
 * This assumes that the label text is the last item in the pipe ("|") delimited indexed field "facet"
 *
 * @param {String} label Default facet label
 * @param {Number} count Default facet count
 * @returns {Object} A React component
 */
function renderAggregationFacetLabel(label, count) {
  let facetSplitArray = label.split("|");
  return (
    <span>
      <span>{facetSplitArray[facetSplitArray.length - 1]}</span>
      <span>{count}</span>
    </span>
  );
}

/**
 * Build an ElasticSearch query of individual items
 * @param {Array} selectedItems Manually selected results from ReactiveSearch search results
 * @returns {Object} An ElasticSearch query
 */
export function buildSelectedItemsQuery(selectedItems = []) {
  return {
    query_string: {
      query: ` id:(${selectedItems.join(" OR ")})`,
    },
  };
}

// Documention: https://docs.appbase.io/docs/reactivesearch/v3/theming/classnameinjection/
const facetClasses = {
  checkbox: "facet-checkbox",
  label: "facet-item-label mx-2",
  title: "facet-title mt-4",
};

const defaultListItemValues = {
  innerClass: facetClasses,
  showSearch: false,
  URLParams: true,
};

/**
 * Helper function to handle boolean value displays
 */
function renderBooleanFacetLabel(label, count) {
  return (
    <span>
      <span>{label ? "YES" : "NO"}</span>
      <span>{count}</span>
    </span>
  );
}

/**
 * Need this as ReactiveSearch complains when we send back a 1/0, instead of true/false
 */
function transformBooleanData(data) {
  return data.map((item) => ({ ...item, key: item.key === 1 }));
}

/**
 * General Metadata Facets
 */
export const FACET_SENSORS = [
  {
    ...defaultListItemValues,
    componentId: "BoxName",
    dataField: "box_name",
    showSearch: true,
    title: "Box Name",
  },
  {
    ...defaultListItemValues,
    componentId: "BoxNumber",
    dataField: "box_number",
    showSearch: false,
    title: "Box Number",
  },
  {
    ...defaultListItemValues,
    componentId: "Contributor",
    dataField: "contributor.label_with_role",
    showSearch: true,
    title: "Contributor",
  },

  {
    ...defaultListItemValues,
    componentId: "Collection",
    dataField: "collection.title.keyword",
    showSearch: true,
    title: "Collection",
  },
  {
    ...defaultListItemValues,
    componentId: "Creator",
    dataField: "creator.label",
    showSearch: true,
    title: "Creator",
  },
  {
    ...defaultListItemValues,
    componentId: "FolderName",
    dataField: "folder_name",
    showSearch: true,
    title: "Folder Name",
  },
  {
    ...defaultListItemValues,
    componentId: "FolderNumber",
    dataField: "folder_number",
    showSearch: false,
    title: "Folder Number",
  },
  {
    ...defaultListItemValues,
    componentId: "Genre",
    dataField: "genre.label",
    showSearch: true,
    title: "Genre",
  },
  {
    ...defaultListItemValues,
    componentId: "Language",
    dataField: "language.label",
    title: "Language",
  },
  {
    ...defaultListItemValues,
    componentId: "LibraryUnit",
    dataField: "library_unit",
    title: "Library Unit",
  },
  {
    ...defaultListItemValues,
    componentId: "License",
    dataField: "license.label",
    title: "License",
  },
  {
    ...defaultListItemValues,
    componentId: "Location",
    dataField: "location.label",
    showSearch: true,
    title: "Location",
  },
  {
    ...defaultListItemValues,
    componentId: "Published",
    dataField: "published",
    renderItem: renderBooleanFacetLabel,
    title: "Published",
    transformData: transformBooleanData,
  },
  {
    ...defaultListItemValues,
    componentId: "RightsStatement",
    dataField: "rights_statement.label",
    title: "Rights Statement",
  },
  {
    ...defaultListItemValues,
    componentId: "Series",
    dataField: "series",
    showSearch: false,
    title: "Series",
  },
  {
    ...defaultListItemValues,
    componentId: "Subject",
    dataField: "subject.label",
    showSearch: true,
    title: "Subject",
  },
  {
    ...defaultListItemValues,
    componentId: "Status",
    dataField: "status",
    showSearch: true,
    title: "Status",
  },
  {
    ...defaultListItemValues,
    componentId: "StylePeriod",
    dataField: "style_period.label",
    showSearch: true,
    title: "Style Period",
  },
  {
    ...defaultListItemValues,
    componentId: "Technique",
    dataField: "technique.label",
    showSearch: true,
    title: "Technique",
  },
  {
    ...defaultListItemValues,
    componentId: "Visibility",
    dataField: "visibility",
    title: "Visibility",
  },
  {
    ...defaultListItemValues,
    componentId: "WorkType",
    dataField: "work_type",
    title: "Work Type",
  },
];

export const FACET_TECHNICAL_METADATA_SENSORS = [
  {
    ...defaultListItemValues,
    componentId: "Compression",
    dataField: "fileSets.extractedMetadata.exif.value.compression.keyword",
    title: "Compression",
  },
  {
    ...defaultListItemValues,
    componentId: "ExtraSamples",
    dataField: "fileSets.extractedMetadata.exif.value.extraSamples.keyword",
    title: "Extra Samples",
  },
  {
    ...defaultListItemValues,
    componentId: "GrayResponseUnit",
    dataField: "fileSets.extractedMetadata.exif.value.grayResponseUnit.keyword",
    title: "Gray Response Unit",
  },
  /**
   * NOTE: Bad data reported in these facets, so temporarily hiding from UI display
   */
  // {
  //   ...defaultListItemValues,
  //   componentId: "Make",
  //   dataField: "fileSets.extractedMetadata.exif.value.make.keyword",
  //   title: "Make",
  // },
  // {
  //   ...defaultListItemValues,
  //   componentId: "Model",
  //   dataField: "fileSets.extractedMetadata.exif.value.model.keyword",
  //   title: "Model",
  // },
  {
    ...defaultListItemValues,
    componentId: "PlanarConfiguration",
    dataField:
      "fileSets.extractedMetadata.exif.value.planarConfiguration.keyword",
    title: "Planar Configuration",
  },
  {
    ...defaultListItemValues,
    componentId: "PhotometricInterpretation",
    dataField:
      "fileSets.extractedMetadata.exif.value.photometricInterpretation.keyword",
    title: "Photometric Interpretation",
  },
];

export const FACET_PROJECT_SENSORS = [
  {
    ...defaultListItemValues,
    componentId: "IngestProject",
    dataField: "ingest_project.title",
    showSearch: true,
    title: "Ingest Project",
  },
  {
    ...defaultListItemValues,
    componentId: "IngestSheet",
    dataField: "ingest_sheet.title",
    showSearch: true,
    title: "Ingest Sheet",
  },
  {
    ...defaultListItemValues,
    componentId: "ProjectName",
    dataField: "project.name",
    showSearch: true,
    title: "Project Name",
  },
  {
    ...defaultListItemValues,
    componentId: "ProjectCycle",
    dataField: "project.cycle",
    title: "Project Cycle",
  },
  {
    ...defaultListItemValues,
    componentId: "ProjectManager",
    dataField: "project.manager",
    title: "Project Manager",
  },
  {
    ...defaultListItemValues,
    componentId: "ProjectProposer",
    dataField: "project.proposer",
    title: "Project Proposer",
  },
  {
    ...defaultListItemValues,
    componentId: "ProjectTaskNumber",
    dataField: "project.task_number",
    showSearch: true,
    title: "Project Task Number",
  },
];

/**
 * Range Sliders - Facets for Numerical technical metadata
 * ES indexed "fileSets[].extractedMetadata.exif.value" fields:
 * { imageHeight, imageWidth, xResolution, yResolution }:
 */
const rangeClasses = {
  label: "range-label",
  slider: "range-slider",
};

const defaultRangeItemValues = {
  includeNullValues: true,
  innerClass: rangeClasses,
};

export const FACET_RANGE_SENSORS = [
  {
    ...defaultRangeItemValues,
    componentId: "RangeImageHeight",
    dataField: "file_sets.height",
    defaultValue: { start: 0, end: 3000 },
    range: { start: 0, end: 3000 },
    rangeLabels: { start: "0px", end: "3000px" },
    title: "Image Height",
  },
  {
    ...defaultRangeItemValues,
    componentId: "RangeImageWidth",
    dataField: "file_sets.width",
    defaultValue: { start: 0, end: 3000 },
    range: { start: 0, end: 3000 },
    rangeLabels: { start: "0px", end: "3000px" },
    title: "Image Width",
  },
  {
    ...defaultRangeItemValues,
    componentId: "RangeXResolution",
    dataField: "fileSets.extractedMetadata.exif.value.xResolution",
    title: "XResolution",
    range: { start: 0, end: 1000 },
    rangeLabels: { start: "0px", end: "1000px" },
    defaultValue: { start: 0, end: 1000 },
  },
  {
    ...defaultRangeItemValues,
    componentId: "RangeYResolution",
    dataField: "fileSets.extractedMetadata.exif.value.yResolution",
    title: "YResolution",
    range: { start: 0, end: 1000 },
    rangeLabels: { start: "0px", end: "1000px" },
    defaultValue: { start: 0, end: 1000 },
  },
];

/**
 * Grab the search string and any facet values from an ElasticSearch query object
 * @param {Object} query An ElasticSearch query object
 * @returns { Object } Map object with keys "search" and "terms"
 */
export function extractQueryParts(query = {}) {
  const searchTermKey = "query_string";
  const facetTermsKey = "terms";

  let returnObj = {
    search: "",
    terms: {},
  };

  function findQueryParts(child) {
    if (typeof child !== "object" && child !== null) {
      return;
    }

    // Array value, loop through child objects
    if (Array.isArray(child)) {
      for (let arrayObj of child) {
        findQueryParts(arrayObj);
      }
    }

    // Grab search string
    if (child.hasOwnProperty(searchTermKey)) {
      returnObj.search = child[searchTermKey].query;
      return;
    }

    // Grab facet terms
    if (child.hasOwnProperty(facetTermsKey)) {
      returnObj.terms = { ...returnObj.terms, ...child[facetTermsKey] };
      return;
    }

    for (let property in child) {
      findQueryParts(child[property]);
    }
  }

  // Kick off recursive function
  findQueryParts(query);

  return returnObj;
}
