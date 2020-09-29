import React from "react";
import { MultiList } from "@appbaseio/reactivesearch";
import { FACET_SENSORS, SEARCH_SENSOR } from "../../services/reactive-search";
import { allImagesQuery } from "../../services/elasticsearch";
import { useLocation } from "react-router-dom";

const facetSensors = FACET_SENSORS.map((sensor) => sensor.componentId);

const filterList = (filterId) => {
  let filtersMinusCurrent = facetSensors.filter(
    (filterItem) => filterItem !== filterId
  );

  return [...filtersMinusCurrent, SEARCH_SENSOR];
};

export default function SearchFacetSidebar() {
  const location = useLocation();

  function getDefaultValue(sensor) {
    const externalFacet = location.state && location.state.externalFacet;

    // User didn't click an external facet link to get to the Search screen,
    // or they did click a facet link, but the clicked facet is not what's
    // currently being rendered in the loop.
    if (
      !externalFacet ||
      sensor.componentId !== externalFacet.facetComponentId
    ) {
      return [];
    }

    // User clicked an external facet link and its now active in the loop
    return [externalFacet.value];
  }

  return (
    <div data-testid="search-facet-sidebar-wrapper" className="is-size-7">
      {FACET_SENSORS.map((sensor) => (
        <MultiList
          key={sensor.componentId}
          {...sensor}
          react={{
            and: filterList(sensor.componentId),
          }}
          defaultQuery={() => allImagesQuery}
          defaultValue={getDefaultValue(sensor)}
          URLParams={true}
        />
      ))}
    </div>
  );
}
