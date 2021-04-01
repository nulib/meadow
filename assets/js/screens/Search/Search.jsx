import React, { useState } from "react";
import Layout from "../Layout";
import { SelectedFilters } from "@appbaseio/reactivesearch";
import SearchBar from "@js/components/UI/SearchBar";
import SearchResults from "@js/components/Search/Results";
import SearchFacetSidebar from "@js/components/Search/FacetSidebar";
import { useHistory } from "react-router-dom";
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
            <div className="box">
              <SearchBar />
              <div className="mt-2">
                <SelectedFilters />
              </div>
            </div>

            <div className="box pb-0">
              <PageTitle>Search Results</PageTitle>
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
              <hr />
              <ResultsDisplaySwitcher
                isListView={isListView}
                onGridClick={() => setIsListView(false)}
                onListClick={() => setIsListView(true)}
              />
            </div>

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
