import React, { useState } from "react";
import Layout from "../Layout";
import { SelectedFilters, StateProvider } from "@appbaseio/reactivesearch";
import SearchBar from "../../components/UI/SearchBar";
import SearchResults from "../../components/Search/Results";
import SearchFacetSidebar from "../../components/Search/FacetSidebar";
import { useLocation, useHistory } from "react-router-dom";
import SearchActionRow from "../../components/Search/ActionRow";
import UIResultsDisplaySwitcher from "../../components/UI/ResultsDisplaySwitcher";
import {
  parseESAggregationResults,
  elasticsearchDirectSearch,
  ELASTICSEARCH_AGGREGATION_FIELDS,
} from "../../services/elasticsearch";
import { useBatchDispatch } from "../../context/batch-edit-context";
import { ErrorBoundary } from "react-error-boundary";
import { DisplayAuthorized } from "@js/components/Auth/DisplayAuthorized";
import { FACET_SENSORS, SEARCH_SENSOR } from "@js/services/reactive-search";

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
  const location = useLocation();
  const [isListView, setIsListView] = useState(false);
  const [selectedItems, setSelectedItems] = useState([]);
  const [filteredQuery, setFilteredQuery] = useState();
  const [resultStats, setResultStats] = useState(0);
  const dispatch = useBatchDispatch();

  //const manualQuery = location.state.prevQuery;

  const handleCsvExportAllItems = () => {
    console.log("handle Csv Export All Items");
  };

  const handleCsvExportItems = () => {
    console.log("handle Csv Export Items");
  };

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
    const myQuery = {
      bool: {
        must: [
          {
            match: {
              "model.name": "Image",
            },
          },
          {
            query_string: {
              query: ` id:(${selectedItems.join(" OR ")})`,
            },
          },
        ],
      },
    };

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
    setFilteredQuery(query.query);
  };

  const handleOnDataChange = (resultStats) => {
    // Remove manually selected items when interacting with ReactiveSearch
    // to avoid 'hidden' selected items confusion
    setSelectedItems([]);

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
      {/* <StateProvider
        componentIds={[
          SEARCH_SENSOR,
          ...FACET_SENSORS.map((x) => x.componentId),
        ]}
        render={({ searchState }) => (
          <div>Search State: ${JSON.stringify(searchState)}</div>
        )}
      /> */}
      <section className="section">
        <div className="columns">
          <div className="column is-one-quarter">
            <div className="box">
              <h2 className="title is-size-4">Filter/Facet</h2>
              <SearchFacetSidebar />
            </div>
          </div>
          <div className="column is-three-quarters">
            <div className="box">
              <SearchBar />
              <div className="mt-2">
                <SelectedFilters />
              </div>
            </div>

            <div className="box pb-0">
              <h1 className="title">Search Results</h1>

              <DisplayAuthorized action="delete">
                <SearchActionRow
                  handleCsvExportAllItems={handleCsvExportAllItems}
                  handleCsvExportItems={handleCsvExportItems}
                  handleDeselectAll={handleDeselectAll}
                  handleEditAllItems={handleEditAllItems}
                  handleEditItems={handleEditItems}
                  handleViewAndEdit={handleViewAndEdit}
                  numberOfResults={resultStats.numberOfResults}
                  selectedItems={selectedItems}
                />
              </DisplayAuthorized>
              <hr />
              <UIResultsDisplaySwitcher
                isListView={isListView}
                onGridClick={() => setIsListView(false)}
                onListClick={() => setIsListView(true)}
              />
            </div>

            <ErrorBoundary FallbackComponent={ErrorFallback}>
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

function ErrorFallback({ error }) {
  return (
    <div role="alert" className="notification is-danger">
      <p>There was an error displaying Search</p>
      <p>
        <strong>Error</strong>: {error.message}
      </p>
    </div>
  );
}

export default ScreensSearch;
