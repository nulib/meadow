import React, { useState } from "react";
import Layout from "../Layout";
import { SelectedFilters } from "@appbaseio/reactivesearch";
import SearchBar from "../../components/UI/SearchBar";
import SearchResults from "../../components/Search/Results";
import SearchFacetSidebar from "../../components/Search/FacetSidebar";
import { useHistory } from "react-router-dom";
import SearchActionRow from "../../components/Search/ActionRow";
import UIResultsDisplaySwitcher from "../../components/UI/ResultsDisplaySwitcher";
import {
  parseESAggregationResults,
  elasticsearchDirectSearch,
  ELASTICSEARCH_AGGREGATION_FIELDS,
} from "../../services/elasticsearch";
import { useBatchDispatch } from "../../context/batch-edit-context";

const ScreensSearch = () => {
  let history = useHistory();
  const [isListView, setIsListView] = useState(false);
  const [selectedItems, setSelectedItems] = useState([]);
  const [filteredQuery, setFilteredQuery] = useState();
  const [resultStats, setResultStats] = useState(0);
  const dispatch = useBatchDispatch();

  const handleEditAllItems = async () => {
    // Grab all aggregated Controlled Term items from Elasticsearch directly,
    // to populate the "Remove" items in Batch Edit
    let response = await elasticsearchDirectSearch({
      aggs: { ...ELASTICSEARCH_AGGREGATION_FIELDS },
      query: { ...filteredQuery },
    });

    let parsedAggregations = parseESAggregationResults(response.aggregations);

    // Update the global Batch Edit Context
    dispatch({
      type: "updateSearchResults",
      filteredQuery: { query: filteredQuery },
      parsedAggregations,
      resultStats,
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

  return (
    <Layout>
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
              <SearchActionRow
                handleDeselectAll={handleDeselectAll}
                handleEditAllItems={handleEditAllItems}
                numberOfResults={resultStats.numberOfResults}
                selectedItems={selectedItems}
              />
              <hr />
              <UIResultsDisplaySwitcher
                isListView={isListView}
                onGridClick={() => setIsListView(false)}
                onListClick={() => setIsListView(true)}
              />
            </div>

            <SearchResults
              handleOnDataChange={handleOnDataChange}
              handleQueryChange={handleQueryChange}
              handleSelectItem={handleSelectItem}
              isListView={isListView}
              selectedItems={selectedItems}
            />
          </div>
        </div>
      </section>
    </Layout>
  );
};

export default ScreensSearch;
