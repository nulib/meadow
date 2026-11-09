import {
  FACET_DATE_SENSORS,
  FACET_PROJECT_SENSORS,
  FACET_RANGE_SENSORS,
  FACET_SENSORS,
  FACET_TECHNICAL_METADATA_SENSORS,
  RESULT_SENSOR,
  SEARCH_SENSOR,
} from "@js/services/reactive-search";
import SearchSortControls, {
  SearchSort,
} from "@js/components/Search/SortControls";
import {
  buildSearchSort,
  readStoredSearchSort,
  storeSearchSort,
} from "@js/services/search-sort";

import { IIIFProvider } from "@js/components/IIIF/IIIFProvider";
import PropTypes from "prop-types";
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
  const facetDateSensors = FACET_DATE_SENSORS.map(
    (sensor) => sensor.componentId,
  );
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

  // The chosen sort is remembered across page loads so that leaving the Search
  // screen (e.g. to view a work) and coming back doesn't drop it. The sort is
  // sent through ReactiveList's defaultQuery rather than its sortOptions prop
  // so that every option can carry a tiebreaker (see services/search-sort.js).
  const [sort, setSort] = React.useState<SearchSort>(readStoredSearchSort);

  const defaultQuery = React.useMemo(
    () => ({ ...allWorksQuery, sort: buildSearchSort(sort) }),
    [sort.field, sort.direction],
  );

  const handleSortChange = (next: SearchSort) => {
    setSort(next);
    storeSearchSort(next);
  };

  return (
    <React.Fragment>
      <div data-testid="search-results-component">
        <IIIFProvider>
          <ReactiveList
            componentId={RESULT_SENSOR}
            dataField="accession_number"
            defaultQuery={() => defaultQuery}
            innerClass={{
              list: `${isListView ? "" : "columns is-multiline"}`,
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
                ...facetDateSensors,
                ...facetProjectSensors,
                ...facetTechnicalMetadataSensors,
                //TODO: Leave this in as we might want to display this info in another type of range component
                //...facetRangeSensors,
                SEARCH_SENSOR,
              ],
            }}
            renderResultStats={(stats: {
              numberOfResults: number;
              time: number;
            }) => (
              <div
                className="is-flex is-justify-content-space-between is-align-items-center is-flex-wrap-wrap mb-3"
                style={{ width: "100%" }}
              >
                <p
                  className="is-size-6 has-text-grey"
                  data-testid="search-result-stats"
                >
                  {stats.numberOfResults} results found in {stats.time}ms
                </p>
                <SearchSortControls sort={sort} onChange={handleSortChange} />
              </div>
            )}
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
            URLParams={true}
          />
        </IIIFProvider>
      </div>
    </React.Fragment>
  );
};

export default SearchResults;
