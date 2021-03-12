import React from "react";
import { DataSearch } from "@appbaseio/reactivesearch";
import { ELASTICSEARCH_FIELDS_TO_SEARCH } from "../../services/elasticsearch";
import { RESULT_SENSOR, SEARCH_SENSOR } from "../../services/reactive-search";
import userPreviousQueryParts from "@js/hooks/usePreviousQueryParts";
import useSearchTerm from "@js/hooks/useSearchTerm";
import IconSearch from "@js/components/Icon/Search";

const UISearchBar = () => {
  const queryParts = userPreviousQueryParts();
  const searchTerm = useSearchTerm();

  const prepDefaultValue = () => {
    if (queryParts) {
      return queryParts.search;
    }
    if (searchTerm) {
      return searchTerm;
    }
    return "";
  };

  return (
    <div data-testid="reactive-search-wrapper">
      <DataSearch
        componentId={SEARCH_SENSOR}
        autosuggest={false}
        dataField={ELASTICSEARCH_FIELDS_TO_SEARCH}
        debounce={500}
        defaultValue={prepDefaultValue()}
        fieldWeights={[5, 2, 2]} // These weights correspond to the index positions of ELASTICSEARCH_FIELDS_TO_SEARCH
        filterLabel="Search"
        fuzziness="AUTO"
        icon={<IconSearch />}
        innerClass={{ input: "input is-large rs-input" }}
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
