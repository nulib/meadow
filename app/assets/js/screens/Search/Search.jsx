import React, { useState } from "react";
import Layout from "../Layout";
import { SelectedFilters } from "@appbaseio/reactivesearch";
import SearchBar from "@js/components/UI/SearchBar";
import SearchResults from "@js/components/Search/Results";
import SearchFacetSidebar from "@js/components/Search/FacetSidebar";
import { useHistory, useLocation } from "react-router-dom";
import SearchActionRow from "@js/components/Search/ActionRow";
import {
  parseESAggregationResults,
  elasticsearchDirectSearch,
  ELASTICSEARCH_AGGREGATION_FIELDS,
} from "@js/services/elasticsearch";
import { useBatchDispatch } from "@js/context/batch-edit-context";
import { ErrorBoundary } from "react-error-boundary";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { buildSelectedItemsQuery } from "@js/services/reactive-search";
import {
  FallbackErrorComponent,
  PageTitle,
  ResultsDisplaySwitcher,
} from "@js/components/UI/UI";
import useGTM from "@js/hooks/useGTM";

async function getParsedAggregations(query) {
  try {
    // Grab all aggregated Controlled Term items from Elasticsearch directly,
    // to populate the "Remove" items in Batch Edit
    let response = await elasticsearchDirectSearch({
      aggs: { ...ELASTICSEARCH_AGGREGATION_FIELDS },
      query: { ...query },
    });
    return parseESAggregationResults(response.aggregations);
  } catch (e) {
    console.error("Error getting parsed aggregations", e);
  }
  return {};
}

const ScreensSearch = () => {
  let history = useHistory();
  const [isListView, setIsListView] = useState(false);
  const [selectedItems, setSelectedItems] = useState([]);
  const [filteredQuery, setFilteredQuery] = useState();
  const [resultStats, setResultStats] = useState(0);
  const dispatch = useBatchDispatch();
  const { loadDataLayer } = useGTM();

  /** 
   * This helper function doesn't appear to be doing it's job any more
   * of allowing a single click to go back into a saved Search.  But
   * since we're pinning to a previous version of ReactiveSearch, maybe
   * this has some value into the future.
   * 
  React.useEffect(() => {
    loadDataLayer({ pageTitle: "Search" });

    function handlePopState(e) {
      // If ReactiveSearch pushed a state onto the history stack
      // take user directly to the previous screen.
      if (e.state?.state) {
        window.history.go(-1);
      }
    }
    // Handle browser's "back" button click
    window.addEventListener("popstate", handlePopState);

    return () => window.removeEventListener("popstate", handlePopState);
  }, []);
   */

  const handleEditAllItems = async () => {
    const parsedAggregations = await getParsedAggregations(filteredQuery);

    // Update the global Batch Edit Context
    dispatch({
      type: "updateSearchResults",
      filteredQuery: { query: filteredQuery },
      parsedAggregations,
      resultStats,
    });

    history.push("/batch-edit");
  };

  // Handle user selected search result items by constructing an Elasticsearch query
  const handleEditItems = async () => {
    const myQuery = buildSelectedItemsQuery(selectedItems);
    const parsedAggregations = await getParsedAggregations(myQuery);

    // Update the global Batch Edit Context
    dispatch({
      type: "updateSearchResults",
      filteredQuery: { query: myQuery },
      parsedAggregations,
      resultStats: { numberOfResults: selectedItems.length },
    });

    history.push("/batch-edit");
  };

  const handleDeselectAll = () => {
    setSelectedItems([]);
  };

  const handleQueryChange = (query) => {
    // Remove manually selected items when interacting with ReactiveSearch
    // to avoid 'hidden' selected items confusion
    setSelectedItems([]);

    setFilteredQuery(query.query);
  };

  const handleOnDataChange = (resultStats) => {
    setResultStats({ ...resultStats });
  };

  const handleSelectItem = (id) => {
    let arr = [...selectedItems];
    const index = arr.indexOf(id);

    if (index > -1) {
      arr.splice(index, 1);
      setSelectedItems(arr);
    } else {
      setSelectedItems([...arr, id]);
    }
  };

  const handleViewAndEdit = () => {
    dispatch({
      type: "updateEditAndViewWorks",
      items: selectedItems,
    });

    history.push(
      `/work/${selectedItems[0]}/multi/${0},${selectedItems.length}`
    );
  };

  return (
    <Layout>
      <section className="section">
        <div className="columns">
          <div className="column is-one-quarter">
            <h2 className="title is-size-4">Filter/Facet</h2>
            <SearchFacetSidebar />
          </div>
          <div className="column is-three-quarters">
            <PageTitle>Search</PageTitle>
            <div className="block mb-5">
              <SearchBar />
              <div className="mt-2">
                <SelectedFilters />
              </div>
            </div>

            <AuthDisplayAuthorized level="EDITOR">
              <SearchActionRow
                handleDeselectAll={handleDeselectAll}
                handleEditAllItems={handleEditAllItems}
                handleEditItems={handleEditItems}
                handleViewAndEdit={handleViewAndEdit}
                numberOfResults={resultStats.numberOfResults}
                selectedItems={selectedItems}
                filteredQuery={filteredQuery}
              />
            </AuthDisplayAuthorized>

            <ResultsDisplaySwitcher
              isListView={isListView}
              onGridClick={() => setIsListView(false)}
              onListClick={() => setIsListView(true)}
            />

            <ErrorBoundary FallbackComponent={FallbackErrorComponent}>
              <SearchResults
                handleOnDataChange={handleOnDataChange}
                handleQueryChange={handleQueryChange}
                handleSelectItem={handleSelectItem}
                isListView={isListView}
                selectedItems={selectedItems}
              />
            </ErrorBoundary>
          </div>
        </div>
      </section>
    </Layout>
  );
};

export default ScreensSearch;
