import React from "react";
import { DataSearch } from "@appbaseio/reactivesearch";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

const UISearchBar = () => {
  return (
    <section className="section has-background-dark">
      <div className="container" data-testid="reactive-search-bar">
        <DataSearch
          componentId="SearchSensor"
          autosuggest={true}
          dataField={["accession_number"]}
          debounce={100}
          filterLabel="Work filter"
          fuzziness={0}
          highlight={true}
          highlightField="title"
          icon={<FontAwesomeIcon icon="search" />}
          innerClass={{ input: "input is-medium" }}
          queryFormat="or"
          placeholder="Search Meadow"
          react={{
            and: ["SearchResult"]
          }}
          size={10}
          showClear={true}
          showFilter={true}
          URLParams={true}
        />
      </div>
    </section>
  );
};

export default UISearchBar;
