import React from "react";

/**
 * Helper function to parse out text presented to the user in Facet labels
 *
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

export const REACTIVE_SEARCH_THEME = {
  typography: {
    fontFamily: "Akkurat Pro Regular",
  },
};

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

// Map of Facet "sensor id" values which ReactiveSearch needs to pull in
// multiple ReactiveSearch "List Components" into search bar and results list
//
// Make each object match the shape of this API:
// https://docs.appbase.io/docs/reactivesearch/v3/list/multilist/
export const FACET_SENSORS = [
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
    componentId: "Visibility",
    dataField: "visibility.label.keyword",
    title: "Visibility",
  },
];

export const SEARCH_SENSOR = "SearchSensor";
