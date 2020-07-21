import React from "react";

export const REACTIVE_SEARCH_THEME = {
  typography: {
    fontFamily: "Akkurat Pro Regular",
  },
};

const facetClasses = {
  label: "facet-item-label",
  checkbox: "facet-checkbox",
};

const defaultListItemValues = {
  innerClass: facetClasses,
  showSearch: false,
};

// Map of Facet "sensor id" values which ReactiveSearch needs to pull in
// multiple ReactiveSearch "List Components" into search bar and results list
//
// Make each object match the shape of this API:
// https://docs.appbase.io/docs/reactivesearch/v3/list/multilist/
export const FACET_SENSORS = [
  {
    ...defaultListItemValues,
    componentId: "FacetCollection",
    dataField: "collection.id",
    showSearch: true,
    title: "Collection",
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
    componentId: "FacetVisibility",
    dataField: "visibility.id",
    title: "Visibility",
  },
];
