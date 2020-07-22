import React from "react";
import { MultiList } from "@appbaseio/reactivesearch";
import { FACET_SENSORS } from "../../services/reactive-search";

export default function SearchFacetSidebar() {
  return (
    <div data-testid="search-facet-sidebar-wrapper">
      {FACET_SENSORS.map((sensor) => (
        <MultiList key={sensor.componentId} {...sensor} />
      ))}
    </div>
  );
}
