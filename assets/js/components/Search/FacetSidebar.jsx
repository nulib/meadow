import React from "react";
import {
  DynamicRangeSlider,
  MultiList,
  RangeSlider,
  SingleRange,
} from "@appbaseio/reactivesearch";
import {
  FACET_SENSORS,
  FACET_RANGE_SENSOR,
  FACET_RANGE_SENSORS,
  SEARCH_SENSOR,
} from "@js/services/reactive-search";
import { useLocation } from "react-router-dom";
import userPreviousQueryParts from "@js/hooks/usePreviousQueryParts";
import { allImagesQuery } from "@js/services/elasticsearch";

const facetSensors = FACET_SENSORS.map((sensor) => sensor.componentId);
const facetRangeSensors = FACET_RANGE_SENSORS.map(
  (sensor) => sensor.componentId
);

const filterList = (filterId) => {
  let filtersMinusCurrent = facetSensors.filter(
    (filterItem) => filterItem !== filterId
  );
  return [...filtersMinusCurrent, ...facetRangeSensors, SEARCH_SENSOR];
};

const filterRangeList = (filterId) => {
  let filtersMinusCurrent = facetRangeSensors.filter(
    (filterItem) => filterItem !== filterId
  );
  console.log("filtersMinusCurrent", filtersMinusCurrent);
  return [...filtersMinusCurrent, ...facetSensors, SEARCH_SENSOR];
};

export default function SearchFacetSidebar() {
  const location = useLocation();

  // A facet was passed in that we need to activate
  const externalFacet = location.state && location.state.externalFacet;
  const queryParts = userPreviousQueryParts();
  const prevFacets =
    queryParts && Object.keys(queryParts.terms).length > 0
      ? queryParts.terms
      : null;

  function getExternalFacetValue(externalFacet, sensor) {
    if (
      !externalFacet ||
      sensor.componentId !== externalFacet.facetComponentId
    ) {
      return;
    }
    return externalFacet.value;
  }

  function getQueryPartsFacetValue(prevFacets, sensor) {
    if (!prevFacets) {
      return [];
    }

    // It's a facet sensor match, grab the value
    if (prevFacets.hasOwnProperty(sensor.dataField)) {
      return prevFacets[sensor.dataField];
    }
    return [];
  }

  // Populate ReactiveSearch MultiList component with default values
  function getDefaultValue(sensor) {
    if (!externalFacet && !prevFacets) {
      return [];
    }

    // User clicked a link to Search screen with an external facet value attached
    const externalFacetValue = getExternalFacetValue(externalFacet, sensor);
    if (externalFacetValue) return [externalFacetValue];

    // Handle facet values from a manual Elasticsearch query
    return getQueryPartsFacetValue(prevFacets, sensor);
  }

  return (
    <div data-testid="search-facet-sidebar-wrapper" className="is-size-7">
      {FACET_SENSORS.map((sensor) => (
        <MultiList
          key={sensor.componentId}
          {...sensor}
          defaultValue={getDefaultValue(sensor)}
          defaultQuery={() => allImagesQuery}
          react={{
            and: filterList(sensor.componentId),
          }}
          showFilter={true}
          URLParams={true}
        />
      ))}
      <hr />
      <h3 className="title is-size-5">Numerical Technical Metadata</h3>
      {FACET_RANGE_SENSORS.map((sensor) => (
        <RangeSlider
          key={sensor.componentId}
          {...sensor}
          react={{
            and: filterRangeList(sensor.componentId),
          }}
          tooltipTrigger="hover"
        />
      ))}
    </div>
  );
}
