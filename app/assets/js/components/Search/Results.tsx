import {
  FACET_PROJECT_SENSORS,
  FACET_RANGE_SENSORS,
  FACET_SENSORS,
  FACET_TECHNICAL_METADATA_SENSORS,
  RESULT_SENSOR,
  SEARCH_SENSOR,
} from "@js/services/reactive-search";

import { IIIFProvider } from "@js/components/IIIF/IIIFProvider";
import PropTypes from "prop-types";
import { REACTIVESEARCH_SORT_OPTIONS } from "@js/services/global-vars";
import React from "react";
import { ReactiveList } from "@appbaseio/reactivesearch";
import SearchSelectable from "@js/components/Search/Selectable";
import UISkeleton from "@js/components/UI/Skeleton";
import WorkCardItem from "@js/components/Work/CardItem";
import WorkListItem from "@js/components/Work/ListItem";
import { allWorksQuery } from "@js/services/elasticsearch";
import { prepWorkItemForDisplay } from "@js/services/helpers";

interface SearchResultsProps {
  handleOnDataChange: (obj: any) => void;
  handleQueryChange: (obj: any) => void;
  handleSelectItem: (obj: any) => void;
  isListView: boolean;
  selectedItems: string[];
}

const SearchResults: React.FC<SearchResultsProps> = ({
  handleOnDataChange,
  handleQueryChange,
  handleSelectItem,
  isListView,
  selectedItems,
}) => {
  const facetSensors = FACET_SENSORS.map((sensor) => sensor.componentId);
  const facetProjectSensors = FACET_PROJECT_SENSORS.map(
    (sensor) => sensor.componentId,
  );
  //TODO: Leave this in as we might want to display this info in another type of range component
  // const facetRangeSensors = FACET_RANGE_SENSORS.map(
  //   (sensor) => sensor.componentId
  // );
  const facetTechnicalMetadataSensors = FACET_TECHNICAL_METADATA_SENSORS.map(
    (sensor) => sensor.componentId,
  );

  return (
    <React.Fragment>
      <div data-testid="search-results-component">
        <IIIFProvider>
          <ReactiveList
            componentId={RESULT_SENSOR}
            dataField="accession_number"
            defaultQuery={() => allWorksQuery}
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
              and: [
                ...facetSensors,
                ...facetProjectSensors,
                ...facetTechnicalMetadataSensors,
                //TODO: Leave this in as we might want to display this info in another type of range component
                //...facetRangeSensors,
                SEARCH_SENSOR,
              ],
            }}
            renderItem={(res) => {
              const isSelected = Boolean(selectedItems.indexOf(res._id) > -1);
              if (isListView) {
                return (
                  <SearchSelectable
                    key={res._id}
                    id={res._id}
                    handleSelectItem={handleSelectItem}
                    isSelected={isSelected}
                  >
                    <div key={res._id} className="box">
                      <WorkListItem
                        key={res._id}
                        {...prepWorkItemForDisplay(res)}
                      />
                    </div>
                  </SearchSelectable>
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
                    isSelected={isSelected}
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
            size={60}
            sortOptions={REACTIVESEARCH_SORT_OPTIONS}
            URLParams={true}
          />
        </IIIFProvider>
      </div>
    </React.Fragment>
  );
};

export default SearchResults;
