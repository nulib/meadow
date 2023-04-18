import { RESULT_SENSOR, SEARCH_SENSOR } from "@js/services/reactive-search";

import { DataSearch } from "@appbaseio/reactivesearch";
import { IconSearch } from "@js/components/Icon";
import React from "react";
import useSearchTerm from "@js/hooks/useSearchTerm";
import userPreviousQueryParts from "@js/hooks/usePreviousQueryParts";

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

  const dataField = [
    {
      field: "title",
      weight: 5,
    },
    {
      field: "description",
      weight: 3,
    },
    {
      field: "collection.title",
      weight: 2,
    },
    {
      field: "subject",
      weight: 2,
    },
    {
      field: "contributor",
      weight: 2,
    },
    {
      field: "full_text",
      weight: 1,
    },
    {
      field: "accession_number",
      weight: 1,
    },
  ];

  return (
    <div data-testid="reactive-search-wrapper">
      <DataSearch
        componentId={SEARCH_SENSOR}
        autosuggest={false}
        dataField={dataField}
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
