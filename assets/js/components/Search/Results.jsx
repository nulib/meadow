import React, { useState } from "react";
import PropTypes from "prop-types";
import { IIIFProvider } from "../../components/IIIF/IIIFProvider";
import { ReactiveList } from "@appbaseio/reactivesearch";
import WorkListItem from "../../components/Work/ListItem";
import WorkCardItem from "../../components/Work/CardItem";
import UISkeleton from "../../components/UI/Skeleton";
import SearchSelectable from "../../components/Search/Selectable";
import { FACET_SENSORS } from "../../services/reactive-search";

const SearchResults = ({
  handleOnDataChange,
  handleQueryChange,
  handleSelectItem,
  isListView,
  selectedItems,
}) => {
  const facetSensors = FACET_SENSORS.map((sensor) => sensor.componentId);

  const getWorkItem = (res) => {
    return {
      id: res._id,
      collectionName: res.collection ? res.collection.title : "",
      title: res.descriptiveMetadata.title,
      updatedAt: res.modified_date,
      representativeImage: res.representativeFileSet,
      manifestUrl: res.iiifManifest,
      published: res.published,
      visibility: res.visibility,
      fileSets: res.fileSets.length,
      accessionNumber: res.accessionNumber,
      workType: res.workType,
    };
  };

  return (
    <>
      <div data-testid="search-results-component">
        <IIIFProvider>
          <ReactiveList
            componentId="SearchResult"
            dataField="accession_number"
            defaultQuery={() => ({
              query: {
                bool: {
                  must: [
                    {
                      match: {
                        "model.name": "Image",
                      },
                    },
                  ],
                },
              },
            })}
            innerClass={{
              list: `${isListView ? "" : "columns is-multiline"}`,
              resultStats: "column is-size-6 has-text-grey",
            }}
            loader={<UISkeleton rows={10} />}
            onData={(obj) => {
              handleOnDataChange({ ...obj.resultStats });
            }}
            onQueryChange={function (prevQuery, nextQuery) {
              handleQueryChange(nextQuery);
            }}
            react={{
              and: [...facetSensors, "SearchSensor"],
            }}
            renderItem={(res) => {
              if (isListView) {
                return (
                  <div key={res._id} className="box">
                    <SearchSelectable
                      key={res._id}
                      id={res._id}
                      handleSelectItem={handleSelectItem}
                      wrapsItemType="list"
                    >
                      <WorkListItem key={res._id} {...getWorkItem(res)} />
                    </SearchSelectable>
                  </div>
                );
              }
              return (
                <div
                  key={res._id}
                  className="column is-half-tablet is-one-third-desktop is-one-quarter-widescreen"
                >
                  <SearchSelectable
                    key={res._id}
                    id={res._id}
                    handleSelectItem={handleSelectItem}
                    isSelected={selectedItems.indexOf(res._id) > -1}
                    wrapsItemType="card"
                  >
                    <WorkCardItem key={res._id} {...getWorkItem(res)} />
                  </SearchSelectable>
                </div>
              );
            }}
            showResultStats={true}
          />
        </IIIFProvider>
      </div>
    </>
  );
};

SearchResults.propTypes = {
  handleOnDataChange: PropTypes.func,
  handleQueryChange: PropTypes.func,
  handleSelectItem: PropTypes.func,
  isListView: PropTypes.bool,
  selectedItems: PropTypes.array,
};

export default SearchResults;
