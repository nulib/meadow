import React from "react";
import { DataSearch } from "@appbaseio/reactivesearch";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { ELASTICSEARCH_FIELDS_TO_SEARCH } from "../../services/elasticsearch";

const UISearchBar = () => {
  return (
    <div data-testid="reactive-search-wrapper">
      <DataSearch
        componentId="SearchSensor"
        autosuggest={true}
        dataField={ELASTICSEARCH_FIELDS_TO_SEARCH}
        debounce={100}
        fieldWeights={[1, 2, 3]}
        filterLabel="Work filter"
        fuzziness={0}
        highlight={true}
        highlightField={ELASTICSEARCH_FIELDS_TO_SEARCH}
        icon={<FontAwesomeIcon icon="search" />}
        innerClass={{ input: "input is-medium" }}
        queryFormat="or"
        placeholder="Search all works"
        size={10}
        showClear={true}
        showFilter={true}
        URLParams={true}
      />
    </div>
  );
};

export default UISearchBar;
