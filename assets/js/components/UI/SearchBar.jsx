import React from "react";
import { DataSearch, SelectedFilters } from "@appbaseio/reactivesearch";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

const UISearchBar = () => {
  return (
    <div data-testid="reactive-search-wrapper">
      <DataSearch
        componentId="SearchSensor"
        autosuggest={true}
        dataField={["title", "description", "accession_number"]}
        debounce={100}
        fieldWeights={[1, 2, 3]}
        filterLabel="Work filter"
        fuzziness={0}
        highlight={true}
        highlightField={["title", "description", "accession_number"]}
        icon={<FontAwesomeIcon icon="search" />}
        innerClass={{ input: "input is-medium" }}
        queryFormat="or"
        placeholder="Search all works"
        react={{
          and: ["SearchResult"],
        }}
        size={10}
        showClear={true}
        showFilter={true}
        URLParams={true}
      />
    </div>
  );
};

export default UISearchBar;
