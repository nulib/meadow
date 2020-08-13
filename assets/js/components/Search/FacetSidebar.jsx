import React from "react";
import { MultiList } from "@appbaseio/reactivesearch";
import { FACET_SENSORS } from "../../services/reactive-search";

const facetSensors = FACET_SENSORS.map((sensor) => sensor.componentId);

const filterList = (filterId) => {
  return facetSensors.filter((filterItem) => filterItem !== filterId);
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
        />
      ))}
    </div>
  );
}
