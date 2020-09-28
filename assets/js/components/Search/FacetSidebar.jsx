import React from "react";
import { MultiList } from "@appbaseio/reactivesearch";
import { FACET_SENSORS, SEARCH_SENSOR } from "../../services/reactive-search";
import { allImagesQuery } from "../../services/elasticsearch";

const facetSensors = FACET_SENSORS.map((sensor) => sensor.componentId);

const filterList = (filterId) => {
  let filtersMinusCurrent = facetSensors.filter(
    (filterItem) => filterItem !== filterId
  );

  return [...filtersMinusCurrent, SEARCH_SENSOR];
};

export default function SearchFacetSidebar() {
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
          URLParams={true}
        />
      ))}
    </div>
  );
}
