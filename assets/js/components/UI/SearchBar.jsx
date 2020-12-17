import React from "react";
import { DataSearch } from "@appbaseio/reactivesearch";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { ELASTICSEARCH_FIELDS_TO_SEARCH } from "../../services/elasticsearch";
import { RESULT_SENSOR, SEARCH_SENSOR } from "../../services/reactive-search";
import userPreviousQueryParts from "@js/hooks/usePreviousQueryParts";

const UISearchBar = () => {
  const queryParts = userPreviousQueryParts();

  return (
    <div data-testid="reactive-search-wrapper">
      <DataSearch
        componentId={SEARCH_SENSOR}
        autosuggest={false}
        dataField={ELASTICSEARCH_FIELDS_TO_SEARCH}
        debounce={500}
        defaultValue={queryParts ? queryParts.search : null}
        fieldWeights={[5, 2]}
        filterLabel="Search"
        fuzziness="AUTO"
        icon={<FontAwesomeIcon icon="search" />}
        innerClass={{ input: "input is-medium" }}
        queryFormat="or"
        queryString={true} // supports complex search, wildcards, etc.
        placeholder="Search all works"
        react={{ and: [RESULT_SENSOR] }}
        size={10}
        searchOperators={true}
        showClear={true}
        showFilter={true}
        URLParams={true}
      />
    </div>
  );
};

export default UISearchBar;
