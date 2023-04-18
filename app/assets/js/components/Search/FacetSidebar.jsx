import {
  FACET_PROJECT_SENSORS,
  FACET_SENSORS,
  FACET_TECHNICAL_METADATA_SENSORS,
  SEARCH_SENSOR,
} from "@js/services/reactive-search";
import { MultiList, RangeSlider } from "@appbaseio/reactivesearch";

import React from "react";
import { allWorksQuery } from "@js/services/elasticsearch";
import { useLocation } from "react-router-dom";
import userPreviousQueryParts from "@js/hooks/usePreviousQueryParts";

/**
 * Organize the facetable metadata into groups
 */
const facetSensors = FACET_SENSORS.map((sensor) => sensor.componentId);
const facetProjectSensors = FACET_PROJECT_SENSORS.map(
  (sensor) => sensor.componentId
);

// const facetRangeSensors = FACET_RANGE_SENSORS.map(
//   (sensor) => sensor.componentId
// );
const facetTechnicalMetadataSensors = FACET_TECHNICAL_METADATA_SENSORS.map(
  (sensor) => sensor.componentId
);

// Return all connected facets for regular metadata
const filterList = (filterId) => {
  let filtersMinusCurrent = facetSensors.filter(
    (filterItem) => filterItem !== filterId
  );
  return [
    ...filtersMinusCurrent,
    ...facetProjectSensors,
    ...facetTechnicalMetadataSensors,
    //...facetRangeSensors,
    SEARCH_SENSOR,
  ];
};

// Return all connected facets for project metadata
const filterProjectList = (filterId) => {
  let filtersMinusCurrent = facetProjectSensors.filter(
    (filterItem) => filterItem !== filterId
  );
  return [
    ...filtersMinusCurrent,
    ...facetSensors,
    ...facetTechnicalMetadataSensors,
    //...facetRangeSensors,
    SEARCH_SENSOR,
  ];
};

// Return all connected facets for technical metadata
const filterTechnicalMetadataList = (filterId) => {
  let filtersMinusCurrent = facetTechnicalMetadataSensors.filter(
    (filterItem) => filterItem !== filterId
  );
  return [
    ...filtersMinusCurrent,
    ...facetSensors,
    ...facetProjectSensors,
    //...facetRangeSensors,
    SEARCH_SENSOR,
  ];
};

/*
// Return all connected facets for numerical range metadata
const filterRangeList = (filterId) => {
  let filtersMinusCurrent = facetRangeSensors.filter(
    (filterItem) => filterItem !== filterId
  );
  return [
    ...filtersMinusCurrent,
    ...facetSensors,
    ...facetTechnicalMetadataSensors,
    SEARCH_SENSOR,
  ];
};
*/

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

  const defaultMultiListProps = {
    defaultQuery: () => allWorksQuery,
    placeholder: "Filter",
    showFilter: true,
    sortBy: "asc",
    URLParams: true,
  };

  return (
    <div data-testid="search-facet-sidebar-wrapper" className="is-size-7">
      <div className="box" data-testid="general-facets">
        {FACET_SENSORS.map((sensor) => (
          <MultiList
            key={sensor.componentId}
            {...sensor}
            {...defaultMultiListProps}
            defaultValue={getDefaultValue(sensor)}
            missingLabel="None"
            react={{
              and: filterList(sensor.componentId),
            }}
            showMissing={
              ["Published", "ReadingRoom"].indexOf(sensor.componentId) > -1
                ? false
                : true
            }
          />
        ))}
      </div>

      <div className="box" data-testid="technical-facets">
        <h3 className="title is-size-5">Technical Metadata</h3>
        {FACET_TECHNICAL_METADATA_SENSORS.map((sensor) => (
          <MultiList
            key={sensor.componentId}
            {...sensor}
            {...defaultMultiListProps}
            defaultValue={getDefaultValue(sensor)}
            react={{
              and: filterTechnicalMetadataList(sensor.componentId),
            }}
          />
        ))}
      </div>

      <div className="box" data-testid="project-facets">
        <h3 className="title is-size-5">Ingest Sheet and Project Metadata</h3>
        {FACET_PROJECT_SENSORS.map((sensor) => (
          <MultiList
            key={sensor.componentId}
            {...sensor}
            {...defaultMultiListProps}
            defaultValue={getDefaultValue(sensor)}
            react={{
              and: filterProjectList(sensor.componentId),
            }}
          />
        ))}
      </div>

      <hr />

      {/* {FACET_RANGE_SENSORS.map((sensor) => (
        <RangeSlider
          key={sensor.componentId}
          {...sensor}
          react={{
            and: filterRangeList(sensor.componentId),
          }}
          tooltipTrigger="hover"
        />
      ))} */}
    </div>
  );
}
