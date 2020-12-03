import React from "react";
import { DataSearch } from "@appbaseio/reactivesearch";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { ELASTICSEARCH_FIELDS_TO_SEARCH } from "../../services/elasticsearch";
import { SEARCH_SENSOR } from "../../services/reactive-search";
import { useHistory } from "react-router-dom";
const UISearchBar = () => {
  const history = useHistory();
  //https://github.com/appbaseio/reactivesearch/issues/834#issuecomment-479961770
  return (
    <div data-testid="reactive-search-wrapper">
      <DataSearch
        componentId={SEARCH_SENSOR}
        // autosuggest={true}
        dataField={ELASTICSEARCH_FIELDS_TO_SEARCH}
        debounce={100}
        fieldWeights={[5, 2]}
        filterLabel="Search"
        fuzziness={0}
        highlight={true}
        highlightField={ELASTICSEARCH_FIELDS_TO_SEARCH}
        icon={<FontAwesomeIcon icon="search" />}
        innerClass={{ input: "input is-medium" }}
        queryFormat="or"
        placeholder="Search all works"
        size={10}
        searchOperators={true}
        // setSearchParams={(params) => {
        //   // history.go(-1);

        //   console.log("set param as :", params);
        // }}
        // onValueChange={function (value) {
        //   console.log("current value: ", value, history.length);
        //   // set the state
        //   // use the value with other js code
        // }}
        // onValueSelected={function (value, cause, source) {
        //   // window.history.go(-1);
        //   console.log("selected value: ", value, history.length, cause, source);
        //   if (cause !== "SUGGESTION_SELECT") {
        //     // use this query
        //     console.log("use this query - onValueSelected: ", this.query);
        //     // this.setState({ redirect: true, value: value }); // value: value
        //     history.push(`?q=${value}`); // added entire line
        //   } else {
        //     // this.valueSelected = true;
        //     // this.setState({ value }); // added enter line
        //   }
        // }}
        // onQueryChange={function (prevQuery, nextQuery) {
        //   // use the query with other js code
        //   console.log("prevQuery", prevQuery);
        //   console.log("nextQuery", nextQuery);
        // }}
        showClear={true}
        showFilter={true}
        URLParams={true}
      />
    </div>
  );
};

export default UISearchBar;
