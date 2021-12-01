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
    bool: {
      must: [
        {
          match: {
            "model.name": "Work",
          },
        },
        {
          query_string: {
            query: ` id.keyword:(${selectedItems.join(" OR ")})`,
          },
        },
      ],
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
 * General Metadata Facets
 */
export const FACET_SENSORS = [
  {
    ...defaultListItemValues,
    componentId: "BoxName",
    dataField: "descriptiveMetadata.boxName.keyword",
    showSearch: true,
    title: "Box Name",
  },
  {
    ...defaultListItemValues,
    componentId: "BoxNumber",
    dataField: "descriptiveMetadata.boxNumber.keyword",
    showSearch: false,
    title: "Box Number",
  },
  {
    ...defaultListItemValues,
    componentId: "Contributor",
    dataField: "descriptiveMetadata.contributor.displayFacet",
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
    dataField: "descriptiveMetadata.creator.displayFacet",
    showSearch: true,
    title: "Creator",
  },
  {
    ...defaultListItemValues,
    componentId: "FolderName",
    dataField: "descriptiveMetadata.folderName.keyword",
    showSearch: true,
    title: "Folder Name",
  },
  {
    ...defaultListItemValues,
    componentId: "FolderNumber",
    dataField: "descriptiveMetadata.folderNumber.keyword",
    showSearch: false,
    title: "Folder Number",
  },
  {
    ...defaultListItemValues,
    componentId: "Genre",
    dataField: "descriptiveMetadata.genre.displayFacet",
    showSearch: true,
    title: "Genre",
  },
  {
    ...defaultListItemValues,
    componentId: "Language",
    dataField: "descriptiveMetadata.language.displayFacet",
    title: "Language",
  },
  {
    ...defaultListItemValues,
    componentId: "LibraryUnit",
    dataField: "administrativeMetadata.libraryUnit.label.keyword",
    title: "Library Unit",
  },
  {
    ...defaultListItemValues,
    componentId: "License",
    dataField: "descriptiveMetadata.license.label.keyword",
    title: "License",
  },
  {
    ...defaultListItemValues,
    componentId: "Location",
    dataField: "descriptiveMetadata.location.displayFacet",
    showSearch: true,
    title: "Location",
  },
  {
    ...defaultListItemValues,
    componentId: "Published",
    dataField: "published",
    renderItem: function (label, count) {
      return (
        <span>
          <span>{label ? "YES" : "NO"}</span>
          <span>{count}</span>
        </span>
      );
    },
    title: "Published",
    // Need this as ReactiveSearch complains when we send back a 1/0, instead of true/false
    transformData: function (data) {
      return data.map((item) => ({ ...item, key: item.key === 1 }));
    },
  },
  {
    ...defaultListItemValues,
    componentId: "RightsStatement",
    dataField: "descriptiveMetadata.rightsStatement.label.keyword",
    title: "Rights Statement",
  },
  {
    ...defaultListItemValues,
    componentId: "Series",
    dataField: "descriptiveMetadata.series.keyword",
    showSearch: false,
    title: "Series",
  },
  {
    ...defaultListItemValues,
    componentId: "Subject",
    dataField: "descriptiveMetadata.subject.displayFacet",
    showSearch: true,
    title: "Subject",
  },
  {
    ...defaultListItemValues,
    componentId: "StylePeriod",
    dataField: "descriptiveMetadata.stylePeriod.displayFacet",
    showSearch: true,
    title: "Style Period",
  },
  {
    ...defaultListItemValues,
    componentId: "Technique",
    dataField: "descriptiveMetadata.technique.displayFacet",
    showSearch: true,
    title: "Technique",
  },
  {
    ...defaultListItemValues,
    componentId: "Visibility",
    dataField: "visibility.label.keyword",
    title: "Visibility",
  },
  {
    ...defaultListItemValues,
    componentId: "WorkType",
    dataField: "workType.label.keyword",
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
    dataField: "project.title.keyword",
    showSearch: true,
    title: "Ingest Project",
  },
  {
    ...defaultListItemValues,
    componentId: "IngestSheet",
    dataField: "sheet.title.keyword",
    showSearch: true,
    title: "Ingest Sheet",
  },
  {
    ...defaultListItemValues,
    componentId: "ProjectName",
    dataField: "administrativeMetadata.projectName.keyword",
    showSearch: true,
    title: "Project Name",
  },
  {
    ...defaultListItemValues,
    componentId: "ProjectCycle",
    dataField: "administrativeMetadata.projectCycle.keyword",
    title: "Project Cycle",
  },
  {
    ...defaultListItemValues,
    componentId: "ProjectManager",
    dataField: "administrativeMetadata.projectManager.keyword",
    title: "Project Manager",
  },
  {
    ...defaultListItemValues,
    componentId: "ProjectProposer",
    dataField: "administrativeMetadata.projectProposer.keyword",
    title: "Project Proposer",
  },
  {
    ...defaultListItemValues,
    componentId: "ProjectTaskNumber",
    dataField: "administrativeMetadata.projectTaskNumber.keyword",
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
    dataField: "fileSets.extractedMetadata.exif.value.imageHeight",
    defaultValue: { start: 0, end: 3000 },
    range: { start: 0, end: 3000 },
    rangeLabels: { start: "0px", end: "3000px" },
    title: "Image Height",
  },
  {
    ...defaultRangeItemValues,
    componentId: "RangeImageWidth",
    dataField: "fileSets.extractedMetadata.exif.value.imageWidth",
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
