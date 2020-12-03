import React, { useState } from "react";
import PropTypes from "prop-types";
import { IIIFProvider } from "@js/components/IIIF/IIIFProvider";
import { ReactiveList } from "@appbaseio/reactivesearch";
import WorkListItem from "@js/components/Work/ListItem";
import WorkCardItem from "@js/components/Work/CardItem";
import UISkeleton from "@js/components/UI/Skeleton";
import SearchSelectable from "@js/components/Search/Selectable";
import { FACET_SENSORS, SEARCH_SENSOR } from "@js/services/reactive-search";
import { prepWorkItemForDisplay } from "@js/services/helpers";
import { allImagesQuery } from "@js/services/elasticsearch";
import { SORT_OPTIONS } from "@js/services/global-vars";
const SearchResults = ({
  handleOnDataChange,
  handleQueryChange,
  handleSelectItem,
  isListView,
  selectedItems,
}) => {
  const facetSensors = FACET_SENSORS.map((sensor) => sensor.componentId);
  return (
    <React.Fragment>
      <div data-testid="search-results-component">
        <IIIFProvider>
          <ReactiveList
            componentId="SearchResult"
            dataField="accession_number"
            defaultQuery={() => allImagesQuery}
            innerClass={{
              list: `${isListView ? "" : "columns is-multiline"}`,
              resultStats: "column is-size-6 has-text-grey",
            }}
            URLParams={true}
            loader={<UISkeleton rows={10} />}
            onData={(obj) => {
              handleOnDataChange({ ...obj.resultStats });
            }}
            onQueryChange={function (prevQuery, nextQuery) {
              handleQueryChange(nextQuery);
            }}
            sortOptions={SORT_OPTIONS}
            react={{
              and: [...facetSensors, SEARCH_SENSOR],
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
                      <WorkListItem
                        key={res._id}
                        {...prepWorkItemForDisplay(res)}
                      />
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
                    <WorkCardItem
                      key={res._id}
                      {...prepWorkItemForDisplay(res)}
                    />
                  </SearchSelectable>
                </div>
              );
            }}
            showResultStats={true}
          />
        </IIIFProvider>
      </div>
    </React.Fragment>
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
