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
    componentId: "FacetContributor",
    dataField: "descriptiveMetadata.contributor.displayFacet",
    showSearch: true,
    title: "Contributor",
  },

  {
    ...defaultListItemValues,
    componentId: "FacetCollection",
    dataField: "collection.id",
    title: "Collection",
  },
  {
    ...defaultListItemValues,
    componentId: "FacetCreator",
    dataField: "descriptiveMetadata.creator.displayFacet",
    showSearch: true,
    title: "Creator",
  },
  {
    ...defaultListItemValues,
    componentId: "FacetGenre",
    dataField: "descriptiveMetadata.genre.displayFacet",
    showSearch: true,
    title: "Genre",
  },
  {
    ...defaultListItemValues,
    componentId: "FacetLanguage",
    dataField: "descriptiveMetadata.language.displayFacet",
    title: "Language",
  },
  {
    ...defaultListItemValues,
    componentId: "FacetLicense",
    dataField: "descriptiveMetadata.license.label.keyword",
    title: "License",
  },
  {
    ...defaultListItemValues,
    componentId: "FacetLocation",
    dataField: "descriptiveMetadata.location.displayFacet",
    showSearch: true,
    title: "Location",
  },
  {
    ...defaultListItemValues,
    componentId: "FacetPublished",
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
    componentId: "FacetRightsStatement",
    dataField: "descriptiveMetadata.rightsStatement.label.keyword",
    title: "Rights Statement",
  },
  {
    ...defaultListItemValues,
    componentId: "FacetSubject",
    dataField: "descriptiveMetadata.subject.displayFacet",
    showSearch: true,
    title: "Subject",
  },
  {
    ...defaultListItemValues,
    componentId: "FacetStylePeriod",
    dataField: "descriptiveMetadata.stylePeriod.displayFacet",
    showSearch: true,
    title: "Style Period",
  },
  {
    ...defaultListItemValues,
    componentId: "FacetVisibility",
    dataField: "visibility.label.keyword",
    title: "Visibility",
  },
];
