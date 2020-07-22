import React, { useState } from "react";
import Layout from "../Layout";
import { SelectedFilters } from "@appbaseio/reactivesearch";
import SearchBar from "../../components/UI/SearchBar";
import SearchResults from "../../components/Search/Results";
import SearchFacetSidebar from "../../components/Search/FacetSidebar";
import { useHistory } from "react-router-dom";

const ScreensSearch = () => {
  let history = useHistory();
  const [selectedItems, setSelectedItems] = useState([]);

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

  const handleGoToEditClick = () => {
    history.push("/batch-edit", {
      items: selectedItems,
    });
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
              <div className="columns">
                <div className="column">
                  <h1 className="title">Search</h1>
                </div>
                <div className="column">
                  <div className="buttons is-right">
                    <button
                      className="button is-primary"
                      onClick={handleGoToEditClick}
                      disabled={selectedItems.length === 0}
                    >
                      Edit Selected Items
                    </button>
                  </div>
                </div>
              </div>
              <SearchBar />
              <div className="mt-2">
                <SelectedFilters />
              </div>
            </div>

            <SearchResults handleSelectItem={handleSelectItem} />
          </div>
        </div>
      </section>
    </Layout>
  );
};

export default ScreensSearch;
